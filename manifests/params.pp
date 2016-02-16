# modules/sigul/manifests/params.pp
#
# == Class: sigul::params
#
# Parameters for the sigul puppet module.
#
# === Authors
#
#   John Florian <jflorian@doubledog.org>
#
# === Copyright
#
# Copyright 2016 John Florian


class sigul::params {

    case $::operatingsystem {

        'CentOS', 'Fedora': {

            # The Client, Bridge and Server are all provided by the same
            # package.
            $packages = 'sigul'

            $bridge_services = 'sigul_bridge'

        }

        default: {
            fail ("${title}: operating system '${::operatingsystem}' is not supported")
        }

    }

}
