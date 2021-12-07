# @api private
class hdp::app_stack::config () {
  ## Mount host certs if the dns_name is equal to the host's name, or
  ## if we set ui_use_tls to true, but don't provide key/cert file paths,
  $_mount_host_certs = $trusted['certname'] == $hdp::app_stack::dns_name

  ## If we are going to be mounting host certs and keys,
  ## we need to run as the owner of these certs and keys in order to not break anything
  if $_mount_host_certs {
    $_final_hdp_user = pick("${facts.dig('hdp_health', 'puppet_user')}", '0')
  }

  ## Handle mounting certs for the UI - 
  ## Which involves HDP Query endpoints and the UI itself
  ## It is recommended that users user their own publically KI certs for these.
  ## If mount_host_certs is true, then we should use the host agents certs,
  ## but we also should for if ui_use_tls is enabled but no paths are provided.
  if $_mount_host_certs or ($hdp::app_stack::ui_use_tls and !$hdp::app_stack::ui_cert_file and !$hdp::app_stack::ui_key_file) {
    $_final_ui_cert_file = "/etc/puppetlabs/puppet/ssl/certs/${trusted['certname']}.pem"
    $_final_ui_key_file = "/etc/puppetlabs/puppet/ssl/private_keys/${trusted['certname']}.pem"
  } else {
    $_final_ui_cert_file =  $hdp::app_stack::ui_cert_file
    $_final_ui_key_file =  $hdp::app_stack::ui_key_file
  }

  if $_mount_host_certs {
    $_final_cert_file = "/etc/puppetlabs/puppet/ssl/certs/${trusted['certname']}.pem"
    $_final_key_file = "/etc/puppetlabs/puppet/ssl/private_keys/${trusted['certname']}.pem"
  } else {
    $_final_cert_file = $hdp::app_stack::cert_file
    $_final_key_file = $hdp::app_stack::key_file
  }

  if !$hdp::app_stack::allow_trust_on_first_use {
    ## All cert_file, key_file, and ca_cert_file must be set if 
    ## allow_trust_on_first_use is true.
    if !$_final_key_file {
      fail('Key file must be provided, or an untrusted download will occur')
    }
    if !$_final_cert_file {
      fail('Cert file must be provided, or an untrusted download will occur')
    }
    if !$hdp::app_stack::ca_cert_file {
      fail('CA Cert file must be provided, or an untrusted download will occur')
    }
  }

  if !defined('$_final_hdp_user') {
    $_final_hdp_user = $hdp::app_stack::hdp_user
  }

  if $hdp::app_stack::version {
    $_final_hdp_version = $hdp::app_stack::version
    $_final_ui_version = $hdp::app_stack::version
    $_final_frontend_version = $hdp::app_stack::version
  } else {
    $_final_hdp_version = $hdp::app_stack::hdp_version
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

  if $hdp::app_stack::hdp_query_auth == 'basic_auth' {
    if $hdp::app_stack::hdp_query_username == undef {
      fail('Basic auth requires username parameter to be set')
    }
    if $hdp::app_stack::hdp_query_password == undef {
      fail('Basic auth requires a query password to be set')
    }
  }
  if $hdp::app_stack::hdp_query_auth == 'oidc' {
    if $hdp::app_stack::hdp_query_oidc_issuer == undef {
      fail('OIDC Auth requires an issuer to validate tokens against')
    }
    if $hdp::app_stack::hdp_query_oidc_client_id == undef {
      fail('OIDC Auth requires a client ID to use')
    }
  }
  if $hdp::app_stack::hdp_query_auth == 'pe_rbac' {
    if $hdp::app_stack::hdp_query_pe_rbac_service == undef {
      fail('PE RBAC Auth requires an RBAC service to validate tokens against')
    }
    ## If PE RBAC is enabled,
    ## ca_cert_file must be set, or it won't work.
    ## we should attempt to use $_final_ca_cert_file,
    ## Which will use one that is downloaded insecurely during the trust-on-first-use step.
    if $hdp::app_stack::hdp_query_pe_rbac_ca_cert_file == undef {
      err('PE RBAC configured, but CA Cert not set - defaulting to downloaded CA Cert. Potentially insecure!')
      $_final_query_pe_rbac_ca_cert_file = $hdp::app_stack::ca_cert_file
    } else {
      $_final_query_pe_rbac_ca_cert_file = $hdp::app_stack::hdp_query_pe_rbac_ca_cert_file
    }
  } else {
    $_final_query_pe_rbac_ca_cert_file = $hdp::app_stack::hdp_query_pe_rbac_ca_cert_file
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
          'hdp_version'                    => $_final_hdp_version,
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
          'hdp_query_pe_rbac_ca_cert_file' => $_final_query_pe_rbac_ca_cert_file,

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
          'key_file'                       => $_final_key_file,
          'cert_file'                      => $_final_cert_file,
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
