#
# == Class: sigul::bridge::firewall
#
# Manages iptables on a host acting as a Sigul Bridge.
#
# === Authors
#
#   John Florian <jflorian@doubledog.org>
#
# === Copyright
#
# This file is part of the doubledog-sigul Puppet module.
# Copyright 2018-2019 John Florian
# SPDX-License-Identifier: GPL-3.0-or-later


class sigul::bridge::firewall (
    ) {

    include 'sigul::bridge'

    firewall {
        '500 accept Sigul client packets':
            dport  => $sigul::bridge::client_listen_port,
            proto  => 'tcp',
            action => 'accept',
            ;
        '500 accept Sigul server packets':
            dport  => $sigul::bridge::server_listen_port,
            proto  => 'tcp',
            action => 'accept',
            ;
    }

}
