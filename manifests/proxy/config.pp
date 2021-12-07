# @api private
class hdp::proxy::config () {
  $_mount_host_certs = $trusted['certname'] == $hdp::proxy::dns_name
  if $_mount_host_certs {
    $_final_hdp_user = pick("${facts.dig('hdp_health', 'puppet_user')}", '0')
    $_final_cert_file = "/etc/puppetlabs/puppet/ssl/certs/${trusted['certname']}.pem"
    $_final_key_file = "/etc/puppetlabs/puppet/ssl/private_keys/${trusted['certname']}.pem"
  } else {
    $_final_hdp_user = $hdp::proxy::hdp_user
    $_final_cert_file =  $hdp::proxy::cert_file
    $_final_key_file =  $hdp::proxy::key_file
  }

  if !$hdp::proxy::allow_trust_on_first_use {
    ## All cert_file, key_file, and ca_cert_file must be set if 
    ## allow_trust_on_first_use is true.
    if !$_final_key_file {
      fail('Key file must be provided, or an untrusted download will occur')
    }
    if !$_final_cert_file {
      fail('Cert file must be provided, or an untrusted download will occur')
    }
    if !$hdp::proxy::ca_cert_file {
      fail('CA Cert file must be provided, or an untrusted download will occur')
    }
  }

  file {
    default:
      ensure  => directory,
      owner   => $_final_hdp_user,
      group   => $_final_hdp_user,
      require => Group['docker'],
      ;
    '/opt/puppetlabs/hdp':
      mode  => '0775',
      ;
    '/opt/puppetlabs/hdp/proxy':
      mode  => '0775',
      ;
    '/opt/puppetlabs/hdp/ssl':
      mode  => '0700',
      ;
    '/opt/puppetlabs/hdp/proxy/docker-compose.yaml':
      ensure  => file,
      mode    => '0440',
      owner   => 'root',
      group   => 'docker',
      content => epp('hdp/hdp-proxy-docker-compose.yaml.epp', {
          'hdp_version'          => $hdp::proxy::version,
          'image_prefix'         => $hdp::proxy::image_prefix,
          'image_repository'     => $hdp::proxy::image_repository,
          'hdp_port'             => $hdp::proxy::hdp_port,

          'ca_server'            => $hdp::proxy::ca_server,
          'key_file'             => $hdp::proxy::key_file,
          'cert_file'            => $hdp::proxy::cert_file,
          'ca_cert_file'         => $hdp::proxy::ca_cert_file,
          'client_key_file'      => $hdp::proxy::client_key_file,
          'client_cert_file'     => $hdp::proxy::client_cert_file,
          'client_ca_cert_file'  => $hdp::proxy::client_ca_cert_file,

          'dns_name'             => $hdp::proxy::dns_name,
          'dns_alt_names'        => $hdp::proxy::dns_alt_names,
          'hdp_user'             => $_final_hdp_user,
          'root_dir'             => '/opt/puppetlabs/hdp',
          'prometheus_namespace' => $hdp::proxy::prometheus_namespace,
          'extra_hosts'          => $hdp::proxy::extra_hosts,

          'hdp_address'          => $hdp::proxy::hdp_address,
          'token'                => $hdp::proxy::token,
          'organization'         => $hdp::proxy::organization,
          'region'               => $hdp::proxy::region,

          'mount_host_certs'     => $_mount_host_certs,
        }
      ),
      ;
  }
}
