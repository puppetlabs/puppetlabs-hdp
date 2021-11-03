# @api private
class hdp::app_stack::config () {
  ## Mount host certs for UI if the dns_name is equal to the host's name, or
  ## if we set ui_use_tls to true, but don't provide key/cert file paths
  ## if one of cert or key is provided, don't force certnames
  $_mount_host_certs = $trusted['certname'] == $hdp::app_stack::dns_name
  if $_mount_host_certs {
    $_final_hdp_user = pick("${facts.dig('hdp_health', 'puppet_user')}", '0')
    $_final_ui_cert_file = "/etc/puppetlabs/puppet/ssl/certs/${trusted['certname']}.pem"
    $_final_ui_key_file = "/etc/puppetlabs/puppet/ssl/private_keys/${trusted['certname']}.pem"
  } else {
    if ($hdp::app_stack::ui_use_tls and !$hdp::app_stack::ui_cert_file and !$hdp::app_stack::ui_key_file) {
      $_final_hdp_user = pick("${facts.dig('hdp_health', 'puppet_user')}", '0')
      $_final_ui_cert_file = "/etc/puppetlabs/puppet/ssl/certs/${trusted['certname']}.pem"
      $_final_ui_key_file = "/etc/puppetlabs/puppet/ssl/private_keys/${trusted['certname']}.pem"
    } else {
      $_final_hdp_user = $hdp::app_stack::hdp_user
      $_final_ui_cert_file =  $hdp::app_stack::ui_cert_file
      $_final_ui_key_file =  $hdp::app_stack::ui_key_file
    }
  }

  $_final_hdp_s3_access_key = $hdp::app_stack::hdp_s3_access_key
  $_final_hdp_s3_secret_key = $hdp::app_stack::hdp_s3_secret_key
  if $hdp::app_stack::hdp_manage_s3 {
    $_final_hdp_s3_endpoint = 'http://minio:9000/'
    $_final_hdp_s3_region = 'hdp'
    $_final_hdp_s3_facts_bucket = 'facts'
    $_final_hdp_s3_disable_ssl = true
    $_final_hdp_s3_force_path_style = true
  } else {
    $_final_hdp_s3_endpoint = $hdp::app_stack::hdp_s3_endpoint
    $_final_hdp_s3_region = $hdp::app_stack::hdp_s3_region
    $_final_hdp_s3_facts_bucket = $hdp::app_stack::hdp_s3_facts_bucket
    $_final_hdp_s3_disable_ssl = $hdp::app_stack::hdp_s3_disable_ssl
    $_final_hdp_s3_force_path_style = $hdp::app_stack::hdp_s3_force_path_style
  }

  if $hdp::app_stack::hdp_manage_es {
    $_final_hdp_es_username = undef
    $_final_hdp_es_password = undef
    $_final_hdp_es_host = 'http://elasticsearch:9200/'
  } else {
    $_final_hdp_es_username = $hdp::app_stack::hdp_es_username
    $_final_hdp_es_password = $hdp::app_stack::hdp_es_password
    $_final_hdp_es_host = $hdp::app_stack::hdp_es_host
  }

  unless $hdp::app_stack::ui_version {
    $_final_ui_version = $hdp::app_stack::hdp_version
  } else {
    $_final_ui_version = $hdp::app_stack::ui_version
  }

  unless $hdp::app_stack::frontend_version {
    $_final_frontend_version = $hdp::app_stack::hdp_version
  } else {
    $_final_frontend_version = $hdp::app_stack::frontend_version
  }

  if $hdp::app_stack::hdp_query_auth == 'basic_auth' {
    if $hdp::app_stack::hdp_query_username == undef {
      fail()
    }
    if $hdp::app_stack::hdp_query_password == undef {
      fail()
    }
  }
  if $hdp::app_stack::hdp_query_auth == 'oidc' {
    if $hdp::app_stack::hdp_query_oidc_issuer == undef {
      fail()
    }
    if $hdp::app_stack::hdp_query_oidc_audience == undef {
      fail()
    }
  }
  if $hdp::app_stack::hdp_query_auth == 'pe_rbac' {
    if $hdp::app_stack::hdp_query_pe_rbac_service == undef {
      fail()
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
    '/opt/puppetlabs/hdp/ssl':
      mode  => '0700',
      ;
    '/opt/puppetlabs/hdp/docker-compose.yaml':
      ensure  => file,
      mode    => '0440',
      owner   => 'root',
      group   => 'docker',
      content => epp('hdp/docker-compose.yaml.epp', {
          'hdp_version'                    => $hdp::app_stack::hdp_version,
          'ui_version'                     => $_final_ui_version,
          'frontend_version'               => $_final_frontend_version,
          'image_prefix'                   => $hdp::app_stack::image_prefix,
          'image_repository'               => $hdp::app_stack::image_repository,
          'hdp_port'                       => $hdp::app_stack::hdp_port,
          'hdp_ui_http_port'               => $hdp::app_stack::hdp_ui_http_port,
          'hdp_ui_https_port'              => $hdp::app_stack::hdp_ui_https_port,
          'hdp_query_port'                 => $hdp::app_stack::hdp_query_port,

          'hdp_query_auth'                 => $hdp::app_stack::hdp_query_auth,
          'hdp_query_username'             => $hdp::app_stack::hdp_query_username,
          'hdp_query_password'             => $hdp::app_stack::hdp_query_password,
          'hdp_query_oidc_issuer'          => $hdp::app_stack::hdp_query_oidc_issuer,
          'hdp_query_oidc_client_id'       => $hdp::app_stack::hdp_query_oidc_client_id,
          'hdp_query_oidc_audience'        => $hdp::app_stack::hdp_query_oidc_audience,
          'hdp_query_pe_rbac_service'      => $hdp::app_stack::hdp_query_pe_rbac_service,
          'hdp_query_pe_rbac_role_id'      => $hdp::app_stack::hdp_query_pe_rbac_role_id,
          'hdp_query_pe_rbac_ca_cert_file' => $hdp::app_stack::hdp_query_pe_rbac_ca_cert_file,

          'elasticsearch_image'            => $hdp::app_stack::elasticsearch_image,
          'redis_image'                    => $hdp::app_stack::redis_image,
          'minio_image'                    => $hdp::app_stack::minio_image,

          'hdp_manage_s3'                  => $hdp::app_stack::hdp_manage_s3,
          'hdp_s3_endpoint'                => $_final_hdp_s3_endpoint,
          'hdp_s3_region'                  => $_final_hdp_s3_region,
          'hdp_s3_access_key'              => $_final_hdp_s3_access_key,
          'hdp_s3_secret_key'              => $_final_hdp_s3_secret_key,
          'hdp_s3_disable_ssl'             => $_final_hdp_s3_disable_ssl,
          'hdp_s3_facts_bucket'            => $_final_hdp_s3_facts_bucket,
          'hdp_s3_force_path_style'        => $_final_hdp_s3_force_path_style,

          'hdp_manage_es'                  => $hdp::app_stack::hdp_manage_es,
          'hdp_es_host'                    => $_final_hdp_es_host,
          'hdp_es_username'                => $_final_hdp_es_username,
          'hdp_es_password'                => $_final_hdp_es_password,

          'ca_server'                      => $hdp::app_stack::ca_server,
          'key_file'                       => $hdp::app_stack::key_file,
          'cert_file'                      => $hdp::app_stack::cert_file,
          'ca_cert_file'                   => $hdp::app_stack::ca_cert_file,

          'ui_use_tls'                     => $hdp::app_stack::ui_use_tls,
          'ui_key_file'                    => $_final_ui_key_file,
          'ui_cert_file'                   => $_final_ui_cert_file,
          'ui_ca_cert_file'                => $hdp::app_stack::ui_ca_cert_file,

          'dns_name'                       => $hdp::app_stack::dns_name,
          'dns_alt_names'                  => $hdp::app_stack::dns_alt_names,
          'hdp_user'                       => $_final_hdp_user,
          'root_dir'                       => '/opt/puppetlabs/hdp',
          'max_es_memory'                  => $hdp::app_stack::max_es_memory,
          'prometheus_namespace'           => $hdp::app_stack::prometheus_namespace,
          'access_log_level'               => $hdp::app_stack::access_log_level,
          'dashboard_url'                  => $hdp::app_stack::dashboard_url,
          'extra_hosts'                    => $hdp::app_stack::extra_hosts,

          'mount_host_certs'               => $_mount_host_certs,
        }
      ),
      ;
  }

  # If TLS is enabled, ensure certificate files are present before docker does
  # its thing and restart containers if the files change.
  if $hdp::app_stack::ui_use_tls and $hdp::app_stack::ui_cert_files_puppet_managed {
    File[$_final_ui_key_file] ~> Docker_compose['hdp']
    File[$_final_ui_cert_file] ~> Docker_compose['hdp']

    if $hdp::app_stack::ui_ca_cert_file {
      File[$hdp::app_stack::ui_ca_cert_file] ~> Docker_compose['hdp']
    }
  }
}
