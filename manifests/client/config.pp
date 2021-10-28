#
# == Define: sigul::client::config
#
# Manages a Sigul Client configuration file.
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


define sigul::client::config (
        String[1]               $bridge_hostname,
        String[1]               $server_hostname,
        Variant[Boolean, Enum['present', 'absent']] $ensure='present',
        String[1]               $client_cert_nickname='sigul-client-cert',
        Stdlib::AbsolutePath    $filename=$title,
        String[1]               $group='sigul',
        Pattern[/[0-7]{4}/]     $mode='0600',
        Optional[String[1]]     $nss_password=undef,
        String[1]               $owner='root',
    ) {

    include 'sigul::client'

    file { $filename:
        ensure    => $ensure,
        owner     => $owner,
        group     => $group,
        mode      => $mode,
        seluser   => 'system_u',
        selrole   => 'object_r',
        seltype   => 'etc_t',
        subscribe => Package[$sigul::client::packages],
        content   => template('sigul/client.conf.erb'),
        show_diff => false,
    }

}
