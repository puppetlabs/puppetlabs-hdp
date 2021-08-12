# Simple class to enable the HDP data processor
#
# @summary Simple class to enable the HDP data processor
#
# @param [HDP::Url] hdp_url
#   The url to send data to.
#
# @param [Boolean] enable_reports
#   Enable sending reports to HDP
#
# @param [Boolean] manage_routes
#   Enable managing the HDP routes file
#
# @param [Boolean] manage_pdb_submit_only_server_urls
#   This setting will allow the `submit_only_server_urls` setting in
#   `puppet.com` to be set when
#   `$collection_method = 'pdb_submit_only_server_urls'` and will allow the
#   setting to be removed when `$collection_method = 'facts_terminus'`.   
#
# @param [Enum['facts_terminus', 'pdb_submit_only_server_urls']] collection_method
#   Determine how the HDP will get its data. When set to `facts_terminus`, this
#   module will setup a new facts terminus to send data. This is the preferred
#   method. When set to `pdb_submit_only_server_urls`, this module will utlize
#   the `submit_only_server_urls` setting of PuppetDB to have it send data as
#   if the HDP server was another instance of PuppetDB. This method should only
#   be used when the facts terminus method cannot be.
#
# @param [String[1]] facts_terminus
#
# @param [String[1]] facts_cache_terminus
#
# @param [Boolean] collect_resources
#
# @param [String[1]] keep_node_re
#
# @param [String[1]] reports
#   A string containg the list of report processors to enable
#
# @param [Optional[Array[Stdlib::HTTPSUrl]]] pdb_submit_only_server_urls
#   An array of PuppetDB instance URLs, including port number, to which
#   commands should be sent, but which shouldn’t ever be queried for data
#   needed during a Puppet run. This setting will use the value of `$hdp_url`
#   unless another value is provided.
#
# @example Configuration in a manifest with default port
#   # Settings applied to both a primary and compilers
#   class { 'profile::primary_and_compilers':
#     class { 'hdp::data_processor':
#       hdp_url => 'https://hdp.example.com:9091',
#     }
#   }
#
# @example Configuration in a manifest with two HDP instances
#   # Settings applied to both a primary and compilers
#   class { 'profile::primary_and_compilers':
#     class { 'hdp::data_processor':
#       hdp_url =>
#         'https://hdp-prod.example.com:9091',
#         'https://hdp-staging.example.com:9091',
#       ],
#     }
#   }
#
# @example Configuration in a manifest using PupeptDB instead of a facts terminus
#   # Settings applied to both a primary and compilers
#   class { 'profile::primary_and_compilers':
#     class { 'hdp::data_processor':
#       hdp_url           => 'https://hdp.example.com:9091',
#       collection_method => 'pdb_submit_only_server_urls',
#     }
#   }
#
# @example Configuration in a manifest using PupeptDB and an additional submit_only_server
#   # Settings applied to both a primary and compilers
#   class { 'profile::primary_and_compilers':
#     class { 'hdp::data_processor':
#       hdp_url                     => 'https://hdp.example.com:9091',
#       collection_method           => 'pdb_submit_only_server_urls',
#       pdb_submit_only_server_urls => [
#         'https://additional-destination.example.com',
#       ],
#     }
#   }
#
# @example Configuration via Hiera with default port
#   ---
#   hdp::data_processor::hdp_url: 'https://hdp.example.com:9091'
#
# @example Configuration via Hiera sending data to two HDP servers
#   ---
#   hdp::data_processor::hdp_url:
#     - 'https://hdp-prod.example.com:9091'
#     - 'https://hdp-staging.example.com:9091'
#
class hdp::data_processor (
  HDP::Url $hdp_url,
  Boolean $enable_reports = true,
  Boolean $manage_routes = true,
  Boolean $manage_pdb_submit_only_server_urls = true,
  Boolean $collect_resources = true,
  Enum['facts_terminus', 'pdb_submit_only_server_urls'] $collection_method = 'facts_terminus',
  String[1] $facts_terminus = 'hdp',
  String[1] $facts_cache_terminus = 'hdp',
  String[1] $reports = 'puppetdb,hdp',
  String[1] $keep_node_re = '.*',
  Optional[Array[Stdlib::HTTPSUrl]] $pdb_submit_only_server_urls = undef,
) {
  if $collect_resources {
    include hdp::resource_collector
  }

  if $collection_method == 'facts_terminus' {
    file { '/etc/puppetlabs/hdp':
      ensure => directory,
      mode   => '0755',
      owner  => 'pe-puppet',
      group  => 'pe-puppet',
    }

    if $manage_routes {
      file { '/etc/puppetlabs/hdp/hdp_routes.yaml':
        ensure  => file,
        owner   => pe-puppet,
        group   => pe-puppet,
        mode    => '0640',
        content => epp('hdp/hdp_routes.yaml.epp', {
            'facts_terminus'       => $facts_terminus,
            'facts_cache_terminus' => $facts_cache_terminus,
        }),
        notify  => Service['pe-puppetserver'],
      }

      ini_setting { 'enable hdp_routes.yaml':
        ensure  => present,
        path    => '/etc/puppetlabs/puppet/puppet.conf',
        section => 'master',
        setting => 'route_file',
        value   => '/etc/puppetlabs/hdp/hdp_routes.yaml',
        require => File['/etc/puppetlabs/hdp/hdp_routes.yaml'],
        notify  => Service['pe-puppetserver'],
      }
    }

    file { '/etc/puppetlabs/puppet/hdp.yaml':
      ensure  => file,
      owner   => pe-puppet,
      group   => pe-puppet,
      mode    => '0640',
      content => epp('hdp/hdp.yaml.epp', {
          'hdp_urls'   => Array($hdp_url, true),
          'keep_nodes' => $keep_node_re,
      }),
      notify  => Service['pe-puppetserver'],
    }

    # Remove pdb submit_only_urls related settings
    if $manage_pdb_submit_only_server_urls {
      ini_setting { 'puppetdb_submit_only_server_urls':
        ensure  => absent,
        section => 'main',
        path    => '/etc/puppetlabs/puppet/puppetdb.conf',
        setting => 'submit_only_server_urls',
        notify  => Service['pe-puppetserver'],
      }
    }
  } elsif $collection_method == 'pdb_submit_only_server_urls' {
    if $manage_pdb_submit_only_server_urls {
      if $pdb_submit_only_server_urls {
        validate_array($pdb_submit_only_server_urls)
        $_real_pdb_submit_only_server_urls = unique($pdb_submit_only_server_urls + Array($hdp_url, true))
      } else {
        $_real_pdb_submit_only_server_urls = Array($hdp_url, true)
      }

      ini_setting { 'puppetdb_submit_only_server_urls':
        ensure  => present,
        section => 'main',
        path    => '/etc/puppetlabs/puppet/puppetdb.conf',
        setting => 'submit_only_server_urls',
        value   => $_real_pdb_submit_only_server_urls.join(','),
        notify  => Service['pe-puppetserver'],
      }
    }

    # remove terminus settings
    file { '/etc/puppetlabs/puppet/hdp.yaml':
      ensure => absent,
      notify => Service['pe-puppetserver'],
    }

    if $manage_routes {
      file { '/etc/puppetlabs/hdp/hdp_routes.yaml':
        ensure => absent,
        notify => Service['pe-puppetserver'],
      }

      ini_setting { 'remove routes_file setting from puppet.conf':
        ensure  => absent,
        path    => '/etc/puppetlabs/puppet/puppet.conf',
        section => 'master',
        setting => 'route_file',
        notify  => Service['pe-puppetserver'],
      }
    }
  }
}
