#
# == Class: sigul::bridge::x509
#
# Manages X.509 certificates on a host acting as a Sigul Bridge that uses PKI
# to authenticate itself to a Koji Hub.
#
# === Authors
#
#   John Florian <jflorian@doubledog.org>
#
# === Copyright
#
# This file is part of the doubledog-sigul Puppet module.
# Copyright 2018 John Florian
# SPDX-License-Identifier: GPL-3.0-or-later


class sigul::bridge::x509 (
        Optional[String[1]]     $client_ca_cert_content,
        Optional[String[1]]     $client_ca_cert_source,
        Optional[String[1]]     $client_cert_content,
        Optional[String[1]]     $client_cert_source,
        Optional[String[1]]     $hub_ca_cert_content,
        Optional[String[1]]     $hub_ca_cert_source,
    ) {

    include 'sigul::bridge'

    # The CA certificates are correct to use openssl::tls_certificate instead
    # of openssl::tls_ca_certificate because they don't need to be general
    # trust anchors.
    openssl::tls_certificate {
        'sigul-client-ca-chain':
            cert_name    => 'client-ca-chain',
            cert_path    => $sigul::bridge::koji_dir,
            cert_content => $client_ca_cert_content,
            cert_source  => $client_ca_cert_source,
            notify       => Service[$sigul::bridge::service],
            ;
        'sigul-hub-ca-chain':
            cert_name    => 'hub-ca-chain',
            cert_path    => $sigul::bridge::koji_dir,
            cert_content => $hub_ca_cert_content,
            cert_source  => $hub_ca_cert_source,
            notify       => Service[$sigul::bridge::service],
            ;
        'sigul':
            cert_name    => 'sigul',
            cert_path    => $sigul::bridge::koji_dir,
            cert_content => $client_cert_content,
            cert_source  => $client_cert_source,
            notify       => Service[$sigul::bridge::service],
            ;
    }

}
