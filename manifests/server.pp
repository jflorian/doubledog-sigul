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
# === Authors
#
#   John Florian <jflorian@doubledog.org>
#
# === Copyright
#
# Copyright 2016-2018 John Florian


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
