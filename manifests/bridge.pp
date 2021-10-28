#
# == Class: sigul::bridge
#
# Manages a host as a Sigul Bridge to relay requests between clients and the
# Sigul Server.
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


class sigul::bridge (
        String[1]               $bridge_cert_nickname,
        Integer[1,65535]        $client_listen_port,
        String[1]               $downloads,
        Stdlib::AbsolutePath    $home_dir,
        String[1]               $hub,
        Integer[0]              $max_rpms_payload_size,
        String[1]               $nss_max_tls,
        String[1]               $nss_min_tls,
        String[1]               $nss_password,
        Array[String[1], 1]     $packages,
        Integer[1,65535]        $server_listen_port,
        Stdlib::AbsolutePath    $top_dir,
        String[1]               $web,
        Stdlib::Ensure::Service $ensure,
        Boolean                 $enable,
        Stdlib::AbsolutePath    $koji_dir,
        String[1]               $service,
    ) {

    include 'sigul'

    package { $packages:
        ensure => installed,
    }

    file {
        default:
            owner     => 'sigul',
            group     => 'sigul',
            mode      => '0640',
            seluser   => 'system_u',
            selrole   => 'object_r',
            seltype   => 'etc_t',
            before    => Service[$service],
            notify    => Service[$service],
            subscribe => Package[$packages],
            ;
        '/etc/sigul/bridge.conf':
            owner     => 'root',
            content   => template('sigul/bridge.conf.erb'),
            show_diff => false,
            ;
        [$home_dir, $koji_dir]:
            ensure => directory,
            mode   => '0750',
            ;
        "${koji_dir}/config":
            content => template('sigul/koji.conf.erb'),
            ;
    }

    service { $service:
        ensure     => $ensure,
        enable     => $enable,
        hasrestart => true,
        hasstatus  => true,
        subscribe  => Package[$packages],
    }

}
