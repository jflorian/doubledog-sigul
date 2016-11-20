# modules/sigul/manifests/bridge.pp
#
# == Class: sigul::bridge
#
# Manages a host as a Sigul Bridge to relay requests between clients and the
# Sigul Server.
#
# === Parameters
#
# ==== Required
#
# [*bridge_cert_nickname*]
#   This must be the nickname given to the Sigul Bridge's certificate within
#   the NSS certificate database.  The named certificaate is used to
#   authenticate the Sigul Bridge to the Sigul Server.
#
# [*client_ca_cert*]
#   Puppet source URI providing the CA certificate which signed "sigul_cert".
#   This must be in PEM format and include all intermediate CA certificates,
#   sorted and concatenated from the leaf CA to the root CA.  This
#   certificaate is used to authenticate the Sigul Bridge to the Koji Hub.
#
# [*downloads*]
#   URL of your Koji package download site.
#
# [*hub*]
#   URL of your Koji Hub service.
#
# [*hub_ca_cert*]
#   Puppet source URI providing the CA certificate which signed the Koji Hub
#   certificate.  This must be in PEM format and include all intermediate CA
#   certificates, sorted and concatenated from the leaf CA to the root CA.
#
# [*nss_password*]
#   Password used to protect the NSS certificate database.
#
# [*sigul_cert*]
#   Puppet source URI providing the Sigul Bridge's identity certificate which
#   must be in PEM format.  This certificaate is used to authenticate the
#   Sigul Bridge to the Koji Hub.
#
# [*web*]
#   URL of your Koji Web service.
#
# [*top_dir*]
#   Directory containing Koji's "repos/" directory.
#
# ==== Optional
#
# [*enable*]
#   Instance is to be started at boot.  Either true (default) or false.
#
# [*ensure*]
#   Instance is to be 'running' (default) or 'stopped'.
#
# [*koji_dir*]
#   Directory that is to contain the Koji integration files: configuration,
#   certificates, keys, etc.  Defaults to "/var/lib/sigul/.koji".
#
# === Authors
#
#   John Florian <jflorian@doubledog.org>
#
# === Copyright
#
# Copyright 2016 John Florian


class sigul::bridge (
        $bridge_cert_nickname,
        $client_ca_cert,
        $downloads,
        $hub,
        $hub_ca_cert,
        $nss_password,
        $sigul_cert,
        $top_dir,
        $web,
        $enable=true,
        $ensure='running',
        $koji_dir='/var/lib/sigul/.koji',
    ) inherits ::sigul::params {

    include '::sigul'

    # The CA certificates are correct to use openssl::tls_certificate instead
    # of openssl::tls_ca_certificate because they don't need to be general
    # trust anchors.
    ::openssl::tls_certificate {
        'sigul-client-ca-chain':
            cert_name   => 'client-ca-chain',
            cert_path   => $koji_dir,
            cert_source => $client_ca_cert,
            notify      => Service[$::sigul::params::bridge_services],
            ;
        'sigul-hub-ca-chain':
            cert_name   => 'hub-ca-chain',
            cert_path   => $koji_dir,
            cert_source => $hub_ca_cert,
            notify      => Service[$::sigul::params::bridge_services],
            ;
        'sigul':
            cert_name   => 'sigul',
            cert_path   => $koji_dir,
            cert_source => $sigul_cert,
            notify      => Service[$::sigul::params::bridge_services],
            ;
    }

    File {
        owner     => 'sigul',
        group     => 'sigul',
        mode      => '0640',
        seluser   => 'system_u',
        selrole   => 'object_r',
        seltype   => 'etc_t',
        before    => Service[$::sigul::params::bridge_services],
        notify    => Service[$::sigul::params::bridge_services],
        subscribe => Package[$::sigul::params::packages],
    }

    file {
        '/etc/sigul/bridge.conf':
            owner     => 'root',
            content   => template('sigul/bridge.conf'),
            show_diff => false,
            ;
        $koji_dir:
            ensure => directory,
            mode   => '0750',
            ;
        "${koji_dir}/config":
            content => template('sigul/koji.conf'),
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

    service { $::sigul::params::bridge_services:
        ensure     => $ensure,
        enable     => $enable,
        hasrestart => true,
        hasstatus  => true,
        subscribe  => Package[$::sigul::params::packages],
    }

}
