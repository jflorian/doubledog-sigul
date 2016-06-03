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
#   the NSS certificate database.  The named certificaate is used to
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
#   Instance is to be 'running' (default) or 'stopped'.
#
# === Authors
#
#   John Florian <jflorian@doubledog.org>
#
# === Copyright
#
# Copyright 2016 John Florian


class sigul::server (
        $bridge_hostname,
        $nss_password,
        $server_cert_nickname,
        $database_path='/var/lib/sigul/server.sqlite',
        $enable=true,
        $ensure='running',
    ) inherits ::sigul::params {

    include '::sigul'

    File {
        owner     => 'root',
        group     => 'sigul',
        mode      => '0640',
        seluser   => 'system_u',
        selrole   => 'object_r',
        seltype   => 'etc_t',
        before    => Service[$::sigul::params::server_services],
        notify    => Service[$::sigul::params::server_services],
        subscribe => Package[$::sigul::params::packages],
    }

    file {
        '/etc/sigul/server.conf':
            content => template('sigul/server.conf'),
            ;

        $database_path:
            owner   => 'sigul',
            mode    => '0600',
            seltype => 'var_lib_t',
            ;
    } ->

    exec { 'sigul_server_create_db':
        creates => $database_path,
        require => Package[$::sigul::params::packages],
        user    => 'sigul',
    } ->

    service { $::sigul::params::server_services:
        ensure     => $ensure,
        enable     => $enable,
        hasrestart => true,
        hasstatus  => true,
        subscribe  => Package[$::sigul::params::packages],
    }

}
