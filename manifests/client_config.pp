# modules/sigul/manifests/client_config.pp
#
# == Define: sigul::client_config
#
# Manages a Sigul Client configuration file.
#
# === Parameters
#
# ==== Required
#
# [*namevar*]
#   An arbitrary identifier for the client configuration instance unless the
#   "filename" parameter is not set in which case this must provide the value
#   normally set with the "filename" parameter.
#
# [*bridge_hostname*]
#   The hostname of your Sigul Bridge that will relay requests for this
#   client.
#
# [*server_hostname*]
#   The hostname of your Sigul Server that will process requests for this
#   client.
#
# ==== Optional
#
# [*ensure*]
#   Instance is to be 'present' (default) or 'absent'.
#
# [*owner*]
#   User name or UID to own the configuration file.
#
# [*group*]
#   Group name or GID to which the configuration file belongs.
#
# [*filename*]
#   This may be used in place of "namevar" if it's beneficial to give namevar
#   an arbitrary value.  This should specify the absolute filesystem path to
#   the configuration file.
#
# [*nss_password*]
#   Password for the client's NSS certificate database.  The default is to
#   prompt the client at run-time for this password.
#
# === Authors
#
#   John Florian <john.florian@dart.biz>


define sigul::client_config (
        $bridge_hostname,
        $server_hostname,
        $ensure='present',
        $owner='root',
        $group='sigul',
        $filename=undef,
        $nss_password=undef,
    ) {

    include '::sigul'
    include '::sigul::params'

    if $filename {
        $filename_ = $filename
    } else {
        $filename_ = $name
    }

    file { $filename_:
        ensure    => $ensure,
        owner     => $owner,
        group     => $group,
        mode      => '0644',
        seluser   => 'system_u',
        selrole   => 'object_r',
        seltype   => 'etc_t',
        subscribe => Package[$::sigul::params::packages],
        content   => template('sigul/client.conf'),
    }

}
