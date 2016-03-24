#!/usr/bin/python
#
# This file is managed by Puppet via the "<%= @module_name %>" module.
#
# sigulsign_unsigned.py - A utility to use sigul to sign rpms in koji
#
# Copyright (C) 2009-2013 Red Hat, Inc.
# SPDX-License-Identifier:      GPL-2.0
#
# Authors:
#     Jesse Keating <jkeating@redhat.com>
#
# This program requires koji and sigul installed, as well as configured.

from cStringIO import StringIO
import os
import optparse
import sys
import koji
import getpass
import shutil
import subprocess
import tempfile
import logging

import gpgme

errors = {}

status = 0
rpmdict = {}
unsigned = []
# Should probably set these from a koji config file
SERVERCA = os.path.expanduser('~/.koji/serverca.crt')
CLIENTCA = os.path.expanduser('~/.koji/clientca.crt')
CLIENTCERT = os.path.expanduser('~/.koji/client.crt')
# Setup a dict of our key names as sigul knows them to the actual key ID
# that koji would use. This information can also be obtained using
# SigulHelper() instances
KEYS = {
    # NB: Duplicate, but otherwise harmless entries may exist here due to the
    # way Class[sigul::auto_signer]] must handle key key sharing across
    # distro releases in the key_map parameter.
<% @key_map.each_pair do |k, v| -%>
    '<%= v['key_name'] %>': {
        'id': '<%= v['key_id'].downcase %>',
        'v3': <%= {true => 'True', false => 'False'}[v['v3']] %>
    },
<% end -%>
}


class GPGMEContext(object):
    """ Use it like:

        with GPGMEContext() as ctx:
            #do_stuff(ctx)
    """
    config = """no-auto-check-trustdb
trust-model direct
no-expensive-trust-checks
no-use-agent
cipher-algo AES256
digest-algo SHA512
s2k-digest-algo SHA512
cipher-algo AES256
compress-algo zlib
"""

    def __init__(self, create_homedir=True):
        self.tempdir = tempfile.gettempdir()
        self.create_homedir = create_homedir

        ctx = gpgme.Context()
        gpg_homedir = None
        if create_homedir:
            gpg_homedir = tempfile.mkdtemp(prefix="temporary_gpg_homedir_")
            # FIXME: Hardcoded gpg path
            ctx.set_engine_info(gpgme.PROTOCOL_OpenPGP,
                                "/usr/bin/gpg", gpg_homedir)

            with open(os.path.join(gpg_homedir, 'gpg.conf'),
                      'wb', 0755) as gpg_config_fp:
                gpg_config_fp.write(self.config)

        self.ctx = ctx
        self.gpg_homedir = gpg_homedir

    def __enter__(self):
        return self.ctx

    def __exit__(self, type_, value, traceback):
        gpg_homedir = self.gpg_homedir
        if self.create_homedir and \
                os.path.abspath(gpg_homedir).startswith(self.tempdir):
            shutil.rmtree(gpg_homedir, ignore_errors=True)


def get_key_info(source, filename=False):
    with GPGMEContext() as ctx:
        if filename:
            with open(source, "r") as ifile:
                import_result = ctx.import_(ifile)
        else:
            ifile = StringIO(source)
            import_result = ctx.import_(ifile)

        if import_result.imported != 1:
            raise ValueError(
                "{0} does not contain exactly one GPG key".format(filename))

        imported_fpr = import_result.imports[0][0]
        key = ctx.get_key(imported_fpr)
        first_subkey = key.subkeys[0]
        keyid = first_subkey.keyid[-8:].lower()
        if first_subkey.pubkey_algo == gpgme.PK_DSA:
            v3 = False
        else:
            v3 = True

    return keyid, v3


def get_gpg_agent_passphrase(cache_id, ask=False, error_message="X",
                             prompt="X", description=None):
    gpg_agent = subprocess.Popen(
        ["gpg-connect-agent"], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
        stderr=subprocess.PIPE)

    cmdline = ["GET_PASSPHRASE"]
    if not ask:
        cmdline.append("--no-ask")

    if not description:
        description = "Please enter password for " + cache_id
        description = description.replace(" ", "+")

    cmdline.append(cache_id)
    cmdline.append(error_message)
    cmdline.append(prompt)
    cmdline.append(description)
    cmdline.append("\n")
    cmdline = " ".join(cmdline)

    response, error = gpg_agent.communicate(cmdline)
    if gpg_agent.returncode != 0:
        raise RuntimeError("gpg-agent-connect error: {0}:{1}".format(
            gpg_agent.returncode, error))
    elif not response.startswith("OK"):
        raise RuntimeError("gpg-agent-connect error message: {0}".format(
            response))
    else:
        passphrase = response[3:-1].decode("hex")
        return passphrase
    return None


class KojiHelper(object):
    def __init__(self, arch=None):
        if arch:
            self.kojihub = \
                'http://{arch}.<%= @hub_hostname %>/kojihub'.format(
                    arch=arch)
        else:
            self.kojihub = 'https://<%= @hub_hostname %>/kojihub'
        self.serverca = os.path.expanduser('~/.koji/serverca.crt')
        self.clientca = os.path.expanduser('~/.koji/clientca.crt')
        self.clientcert = os.path.expanduser('~/.koji/client.crt')
        self.kojisession = koji.ClientSession(self.kojihub)
        self.kojisession.ssl_login(self.clientcert, self.clientca,
                                   self.serverca)

    def listTagged(self, tag, inherit=False):
        """ Return list of SRPM NVRs for a tag
        """
        builds = [build['nvr'] for build in
                  self.kojisession.listTagged(tag, latest=True,
                                              inherit=inherit)
                  ]
        return builds

    def get_build_ids(self, nvrs):
        """
        Get build ids for a list of SRPM NVRs
        """
        errors = []

        build_ids = []
        self.kojisession.multicall = True

        for build in nvrs:
            # use strict for now to traceback on bad buildNVRs
            self.kojisession.getBuild(build, strict=True)

        for build, result in zip(nvrs, self.kojisession.multiCall()):
            if isinstance(result, list):
                build_ids.append(result[0]["id"])
            else:
                errors.append(build)
        return build_ids, errors

    def get_rpms(self, build_ids):
        """ Get dict of filenames -> RPM ID for a list of build IDs
        """

        res = {}
        self.kojisession.multicall = True
        if isinstance(build_ids, int):
            build_ids = [build_ids]

        for bID in build_ids:
            self.kojisession.listRPMs(buildID=bID)
        results = self.kojisession.multiCall()
        for [rpms] in results:
            for rpm in rpms:
                filename = "{rpm[nvr]}.{rpm[arch]}.rpm".format(rpm=rpm)
                res[filename] = rpm['id']
        return res

    def get_unsigned_rpms(self, rpms, keyid):
        """ Reduce RPMs to RPMs that are not signed with keyid

            :parameter:rpms: dict RPM filename -> rpm ID
            :returns: dict: RPM filename -> rpm ID
        """
        unsigned = {}
        self.kojisession.multicall = True

        rpm_filenames = rpms.keys()
        for rpm in rpm_filenames:
            self.kojisession.queryRPMSigs(rpm_id=rpms[rpm], sigkey=keyid)

        results = self.kojisession.multiCall()
        for ([result], rpm) in zip(results, rpm_filenames):
            if not result:
                unsigned[rpm] = rpms[rpm]
        return unsigned

    def write_signed_rpms(self, rpms, keyid):
        self.kojisession.multicall = True
        rpm_filenames = list(rpms)
        for rpm in rpm_filenames:
            self.kojisession.writeSignedRPM(rpm, keyid)
        results = self.kojisession.multiCall()
        errors = {}

        for result, rpm in zip(results, rpm_filenames):
            if isinstance(result, dict):
                errors[rpm] = result
            elif result != [None]:
                raise ValueError("Unexpected Koji result: " + repr(result))
        return errors

    def check_build_is_tagged(self, build_id, tag):
        build = self.kojisession.getBuild(build_id)
        if build:
            package_name = build["name"]
            builds = self.kojisession.listTagged(tag, package=package_name)
            build_ids = [b["build_id"] for b in builds]
            if build_id in build_ids:
                return True
        return False


def exit(status):
    """End the program using status, report any errors"""

    if errors:
        for type in errors.keys():
            logging.error('Errors during %s:' % type)
            for fault in errors[type]:
                logging.error('     ' + fault)

    sys.exit(status)


# Throw out some functions
def writeRPMs(status, kojihelper, batch=None):
    """Use the global rpmdict to write out rpms within.
       Returns status, increased by one in case of failure"""

    # Check to see if we want to write all, or just the unsigned.
    if opts.write_all:
        rpms = rpmdict.keys()
    else:
        if batch is None:
            rpms = [rpm for rpm in rpmdict.keys() if rpm in unsigned]
        else:
            rpms = batch
    logging.info('Calling koji to write %s rpms' % len(rpms))
    status = status
    written = 0
    rpmcount = len(rpms)
    while rpms:
        workset = rpms[0:100]
        rpms = rpms[100:]

        for rpm in workset:
            written += 1
            logging.debug('Writing out %s with %s, %s of %s',
                          rpm, key, written, rpmcount)
        errors = kojihelper.write_signed_rpms(workset, KEYS[key]['id'])

        for rpm, result in errors.items():
            logging.error('Error writing out %s' % rpm)
            errors.setdefault('Writing', []).append(rpm)
            if result['traceback']:
                logging.error('    ' + result['traceback'][-1])
            status += 1
    return status


class SigulHelper(object):
    def __init__(self, key, password=None, config_file=None, arch=None,
                 ask_with_agent=False, ask=False):
        """ If password is None, ask for it

        """
        self.key = key

        if password is None:
            try:
                import fedora_cert
                fas_username = fedora_cert.read_user_cert()
            except:
                fas_username = getpass.getuser()

            cache_id = "sigul:{0}:{1}".format(fas_username, key)
            try:
                self.password = get_gpg_agent_passphrase(cache_id,
                                                         ask=ask_with_agent)
            except:
                self.password = None

            if self.password is None and ask and not ask_with_agent:
                self.password = getpass.getpass(
                    prompt='Passphrase for %s: ' % key)
        else:
            self.password = password
        if self.password is None:
            raise ValueError("Missing password")
        self.config_file = config_file
        self.arch = arch

        ret, pubkey, stderr = self.get_public_key()
        if ret != 0:
            raise ValueError("Invalid key or password: " + stderr)
        self.keyid, self.v3 = get_key_info(pubkey)

    def get_public_key(self):
        command = self.build_cmdline('get-public-key', self.key)
        ret, stdout, stderr = self.run_command(command)
        return ret, stdout, stderr

    def build_cmdline(self, *args):
        cmdline = ['sigul', '--batch']
        if self.config_file:
            cmdline.extend(["--config-file", self.config_file])
        cmdline.extend(args)
        return cmdline

    def run_command(self, command):
        child = subprocess.Popen(command, stdin=subprocess.PIPE,
                                 stdout=subprocess.PIPE,
                                 stderr=subprocess.PIPE)
        stdout, stderr = child.communicate(self.password + '\0')
        ret = child.wait()
        return ret, stdout, stderr

    def build_sign_cmdline(self, rpms, arch=None):
        if arch is None:
            arch = self.arch

        if len(rpms) == 1:
            sigul_cmd = "sign-rpm"
        else:
            sigul_cmd = "sign-rpms"

        command = self.build_cmdline(sigul_cmd, '--store-in-koji',
                                     '--koji-only')
        if arch:
            command.extend(['-k', arch])

        if self.v3:
            command.append('--v3-signature')
        command.append(self.key)

        return command + rpms


if __name__ == "__main__":
    # Define our usage
    usage = 'usage: %prog [options] key (build1, build2)'
    # Create a parser to parse our arguments
    parser = optparse.OptionParser(usage=usage)
    parser.add_option('-v', '--verbose', action='count', default=0,
                      help='Be verbose, specify twice for debug')
    parser.add_option('--tag',
                      help='Koji tag to sign, use instead of listing builds')
    parser.add_option('--inherit', action='store_true', default=False,
                      help='Use tag inheritance to find builds.')
    parser.add_option('--just-write', action='store_true', default=False,
                      help='Just write out signed copies of the rpms')
    parser.add_option('--just-sign', action='store_true', default=False,
                      help='Just sign and import the rpms')
    parser.add_option('--just-list', action='store_true', default=False,
                      help='Just list the unsigned rpms')
    parser.add_option('--write-all', action='store_true', default=False,
                      help='Write every rpm, not just unsigned')
    parser.add_option('--password',
                      help='Password for the key')
    parser.add_option('--batch-mode', action="store_true", default=False,
                      help='Read null-byte terminated password from stdin')
    parser.add_option('--arch',
                      help='Architecture when singing secondary arches')
    parser.add_option('--sigul-batch-size',
                      help='Amount of RPMs to sign in a sigul batch',
                      default=50, type="int")
    parser.add_option('--sigul-config-file',
                      help='Config file to use for sigul',
                      default=None, type="str")
    parser.add_option('--gpg-agent',
                      help='Use GPG Agent to ask for password',
                      default=False, action='store_true')
    # Get our options and arguments
    (opts, args) = parser.parse_args()

    if opts.verbose <= 0:
        loglevel = logging.WARNING
    elif opts.verbose == 1:
        loglevel = logging.INFO
    else:  # options.verbose >= 2
        loglevel = logging.DEBUG

    logging.basicConfig(format='%(asctime)s %(levelname)s: %(message)s',
                        level=loglevel)

    # Check to see if we got any arguments
    if not args:
        parser.print_help()
        sys.exit(1)

    # Check to see if we either got a tag or some builds
    if opts.tag and len(args) > 2:
        logging.error('You must provide either a tag or a build.')
        parser.print_help()
        sys.exit(1)

    key = args[0]
    logging.debug('Using %s for key %s' % (KEYS[key]['id'], key))
    if key not in KEYS.keys():
        logging.error('Unknown key %s' % key)
        parser.print_help()
        sys.exit(1)

    # Get the passphrase for the user if we're going to sign something
    # (This code stolen from sigul client.py)
    if not (opts.just_list or opts.just_write):
        if opts.password:
            passphrase = opts.password
        elif opts.batch_mode:
            passphrase = ""
            while True:
                pwchar = sys.stdin.read(1)
                if pwchar == '\0':
                    break
                elif pwchar == '':
                    raise EOFError('Incomplete password')
                else:
                    passphrase += pwchar
        else:
            # let SigulHelper ask
            passphrase = None

        try:
            sigul_helper = SigulHelper(key, passphrase,
                                       config_file=opts.sigul_config_file,
                                       arch=opts.arch, ask=True,
                                       ask_with_agent=opts.gpg_agent)
        except ValueError as error:
            logging.error('Error validating passphrase for key %s: %s', key,
                          error)
            sys.exit(1)

    # setup the koji session
    logging.info('Setting up koji session')
    kojihelper = KojiHelper(arch=opts.arch)
    kojisession = kojihelper.kojisession

    # Get a list of builds
    # If we have a tag option, get all the latest builds from that tag,
    # optionally using inheritance.  Otherwise take everything after the
    # key as a build.
    if opts.tag is not None:
        logging.info('Getting builds from %s' % opts.tag)
        builds = kojihelper.listTagged(opts.tag, inherit=opts.inherit)
    else:
        logging.info('Getting builds from arguments')
        builds = args[1:]

    logging.info('Got %s builds' % len(builds))

    # sort the builds
    builds = sorted(builds)
    buildNVRs = []
    cmd_build_ids = []
    for b in builds:
        if b.isdigit():
            cmd_build_ids.append(int(b))
        else:
            buildNVRs.append(b)

    if buildNVRs != []:
        logging.info('Getting build IDs from Koji')
        build_ids, buildID_errors = kojihelper.get_build_ids(buildNVRs)
        for nvr in buildID_errors:
            logging.error('Invalid n-v-r: %s' % nvr)
            status += 1
            errors.setdefault('buildNVRs', []).append(nvr)
    else:
        build_ids = []

    build_ids.extend(cmd_build_ids)

    # now get the rpm filenames and ids from each build
    logging.info('Getting rpms from each build')
    rpmdict = kojihelper.get_rpms(build_ids)
    logging.info('Found %s rpms' % len(rpmdict))

    # Now do something with the rpms.

    # If --just-write was passed, try to write them all out
    # We try to write them all instead of worrying about which
    # are already written or not.  Calls are cheap, restarting
    # mash isn't.
    if opts.just_write:
        logging.info('Just writing rpms')
        exit(writeRPMs(status, kojihelper))

    # Since we're not just writing things out, we need to figure out what needs
    # to be signed.

    # Get unsigned packages
    logging.info('Checking for unsigned rpms in koji')
    unsigned = list(kojihelper.get_unsigned_rpms(rpmdict, KEYS[key]['id']))
    for rpm in unsigned:
        logging.debug('%s is not signed with %s' % (rpm, key))

    if opts.just_list:
        logging.info('Just listing rpms')
        print('\n'.join(unsigned))
        exit(status)

    # run sigul
    logging.debug('Found %s unsigned rpms' % len(unsigned))
    batchsize = opts.sigul_batch_size

    def run_sigul(rpms, batchnr):
        global status
        logging.info('Signing batch %s/%s with %s rpms' % (
            batchnr, (total + batchsize - 1) / batchsize, len(rpms))
        )
        command = sigul_helper.build_sign_cmdline(rpms)
        logging.debug('Running %s' % subprocess.list2cmdline(command))
        ret = sigul_helper.run_command(command)[0]
        if ret != 0:
            logging.error('Error signing %s' % (rpms))
            for rpm in rpms:
                errors.setdefault('Signing', []).append(rpm)
        status += 1

    logging.info('Signing rpms via sigul')
    total = len(unsigned)
    batchnr = 0
    rpms = []
    for rpm in unsigned:
        rpms += [rpm]
        if len(rpms) == batchsize:
            batchnr += 1
            run_sigul(rpms, batchnr)
            rpms = []

    if len(rpms) > 0:
        batchnr += 1
        run_sigul(rpms, batchnr)

    # Now that we've signed things, time to write them out, if so desired.
    if not opts.just_sign:
        exit(writeRPMs(status, kojihelper))

    logging.info('All done.')
    sys.exit(status)
