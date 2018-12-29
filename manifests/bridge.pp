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
# Copyright 2016-2018 John Florian
# SPDX-License-Identifier: GPL-3.0-or-later


class sigul::bridge (
        String[1]               $bridge_cert_nickname,
        String[1]               $client_ca_cert_source,
        String[1]               $client_cert_source,
        Integer[1,65535]        $client_listen_port,
        String[1]               $downloads,
        String[1]               $home_dir,
        String[1]               $hub,
        String[1]               $hub_ca_cert_source,
        Integer                 $max_rpms_payload_size,
        String[1]               $nss_max_tls,
        String[1]               $nss_min_tls,
        String[1]               $nss_password,
        Array[String[1], 1]     $packages,
        Integer[1,65535]        $server_listen_port,
        String[1]               $top_dir,
        String[1]               $web,
        Variant[Boolean, Enum['running', 'stopped']] $ensure,
        Boolean                 $enable,
        String[1]               $koji_dir,
        String[1]               $service,
    ) {

    include '::sigul'

    package { $packages:
        ensure => installed,
    }

    # The CA certificates are correct to use openssl::tls_certificate instead
    # of openssl::tls_ca_certificate because they don't need to be general
    # trust anchors.
    ::openssl::tls_certificate {
        'sigul-client-ca-chain':
            cert_name   => 'client-ca-chain',
            cert_path   => $koji_dir,
            cert_source => $client_ca_cert_source,
            notify      => Service[$service],
            ;
        'sigul-hub-ca-chain':
            cert_name   => 'hub-ca-chain',
            cert_path   => $koji_dir,
            cert_source => $hub_ca_cert_source,
            notify      => Service[$service],
            ;
        'sigul':
            cert_name   => 'sigul',
            cert_path   => $koji_dir,
            cert_source => $client_cert_source,
            notify      => Service[$service],
            ;
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

    firewall {
        '500 accept Sigul client packets':
            dport  => '44334',
            proto  => 'tcp',
            state  => 'NEW',
            action => 'accept',
            ;
        '500 accept Sigul server packets':
            dport  => '44333',
            proto  => 'tcp',
            state  => 'NEW',
            action => 'accept',
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
