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
# This file is part of the doubledog-sigul Puppet module.
# Copyright 2016-2021 John Florian
# SPDX-License-Identifier: GPL-3.0-or-later


class sigul::server (
        String[1]               $bridge_hostname,
        Integer[1,65535]        $bridge_port,
        String[1]               $nss_password,
        String[1]               $server_cert_nickname,
        Variant[Boolean, Enum['running', 'stopped']] $ensure,
        String[1]               $database_path,
        Boolean                 $enable,
        Array[String[1], 1]     $packages,
        String[1]               $service,
    ) {

    include 'sigul'

    package { $packages:
        ensure => installed,
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
            subscribe => Package[$packages],
            ;
        '/etc/sigul/server.conf':
            content   => template('sigul/server.conf.erb'),
            show_diff => false,
            ;
        $database_path:
            owner   => 'sigul',
            mode    => '0600',
            seltype => 'var_lib_t',
            ;
    }

    -> exec { 'sigul_server_create_db':
        creates => $database_path,
        require => Package[$packages],
        user    => 'sigul',
    }

    -> service { $service:
        ensure     => $ensure,
        enable     => $enable,
        hasrestart => true,
        hasstatus  => true,
        subscribe  => Package[$packages],
    }

}
