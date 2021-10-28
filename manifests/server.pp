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
        Stdlib::Host                $bridge_hostname,
        Stdlib::Port                $bridge_port,
        Stdlib::AbsolutePath        $gnupg_home,
        Integer[768]                $gnupg_key_length,
        String[1]                   $gnupg_key_type,
        Boolean                     $lenient_username_check,
        Integer[0]                  $max_file_payload_size,
        Integer[0]                  $max_memory_payload_size,
        Integer[0]                  $max_rpms_payload_size,
        String[1]                   $nss_password,
        Optional[Array[String[1]]]  $proxy_usernames,
        String[1]                   $server_cert_nickname,
        Stdlib::Ensure::Service     $ensure,
        Stdlib::AbsolutePath        $database_path,
        Boolean                     $enable,
        Array[String[1], 1]         $packages,
        String[1]                   $service,
        Integer[0]                  $signing_timeout,
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
