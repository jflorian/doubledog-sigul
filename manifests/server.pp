# modules/sigul/manifests/server.pp
#
# == Class: sigul::server
#
# Manages a host as a Sigul Server.
#
# For security reasons the Sigul Server should be highly isolated and not
# accept incoming network connections.  Its sole mode of communication should
# be with the Sigul Bridge via connections that the Sigul Server itself
# establishes.
#
# === Parameters
#
# ==== Required
#
# [*bridge_hostname*]
#   The hostname of your Sigul Bridge that will relay requests to this server.
#
# [*nss_password*]
#   Password used to protect the NSS certificate database.
#
# [*server_cert_nickname*]
#   This must be the nickname given to the Sigul Server's certificate within
#   the NSS certificate database.  The named certificate is used to
#   authenticate the Sigul Server to the Sigul Bridge.
#
# ==== Optional
#
# [*database_path*]
#   Filesystem path to the server's SQLite database.  Defaults to
#   '/var/lib/sigul/server.sqlite'.
#
# [*enable*]
#   Instance is to be started at boot.  Either true (default) or false.
#
# [*ensure*]
#   Instance is to be 'running' (default) or 'stopped'.  Alternatively,
#   a Boolean value may also be used with true equivalent to 'running' and
#   false equivalent to 'stopped'.
#
# [*gpg_kludge*]
#   This must be set to true on hosts where gpg defaults to gpg2 until such
#   time that Sigul can work acceptably with gpg2.  For more details, see:
#       https://bugzilla.redhat.com/show_bug.cgi?id=1329747
#
# [*gpg_kludge_packages*]
#   An array of package names needed for the kludging the Sigul installation
#   to work around issues with GPGME.  This is only used if "gpg_kludge" is
#   true.
#
# [*service*]
#   The service name of the Sigul Server.
#
# === Authors
#
#   John Florian <jflorian@doubledog.org>
#
# === Copyright
#
# Copyright 2016-2017 John Florian


class sigul::server (
        String[1]               $bridge_hostname,
        String[1]               $nss_password,
        String[1]               $server_cert_nickname,
        Variant[Boolean, Enum['running', 'stopped']] $ensure,
        String[1]               $database_path,
        Boolean                 $enable,
        Boolean                 $gpg_kludge,
        Array[String[1], 1]     $gpg_kludge_packages,
        String[1]               $service,
    ) {

    include '::sigul'

    if $gpg_kludge {
        package { $gpg_kludge_packages:
            ensure => installed,
        } ->

        file { '/usr/bin/gpg':
            ensure => 'link',
            target => 'gpg1',
        }
    }

    file {
        default:
            owner     => 'root',
            group     => 'sigul',
            mode      => '0640',
            seluser   => 'system_u',
            selrole   => 'object_r',
            seltype   => 'etc_t',
            before    => Service[$service],
            notify    => Service[$service],
            subscribe => Package[$::sigul::packages],
            ;
        '/etc/sigul/server.conf':
            content   => template('sigul/server.conf'),
            show_diff => false,
            ;
        $database_path:
            owner   => 'sigul',
            mode    => '0600',
            seltype => 'var_lib_t',
            ;
    } ->

    exec { 'sigul_server_create_db':
        creates => $database_path,
        require => Package[$::sigul::packages],
        user    => 'sigul',
    } ->

    service { $service:
        ensure     => $ensure,
        enable     => $enable,
        hasrestart => true,
        hasstatus  => true,
        subscribe  => Package[$::sigul::packages],
    }

}
