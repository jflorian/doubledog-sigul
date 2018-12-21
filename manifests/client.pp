#
# == Class: sigul::client
#
# Manages a host as a Sigul Client.
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


class sigul::client (
        Hash[String[1], Hash]   $configs,
        Array[String[1], 1]     $packages,
    ) {

    include '::sigul'

    package { $packages:
        ensure => installed,
    }

    create_resources(sigul::client_config, $configs)

}
