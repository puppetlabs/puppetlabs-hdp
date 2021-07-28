#
# This class takes care of configuring a node to run HDP.
#
# @param [Boolean] create_docker_group
#   Ensure the docker group is present.
#
# @param [Boolean] manage_docker
#   Install and manage docker as part of app_stack
#
# @param [Integer] hdp_port
#   Port to access HDP upload service
#
# @param [Integer] hdp_query_port
#   Port to access HDP query service
#
# @param [Integer] hdp_ui port
#   Port to access HDP UI
#
# @param [Boolean] $hdp_manage_es = true,
#   Allow this module to manage elasticsearch
#   If true, all other es parameters are ignored
#
# @param [String[1]] $hdp_es_host,
#   Elasticsearch host to use
#
# @param [Optional[String[1]]] hdp_es_username,
#   Username to use to connect to elasticsearch
#
# @param [Optional[String[1]]] hdp_es_password,
#   Password to use to connect to elasticsearch
#
# @param [Boolean] $hdp_manage_s3,
#   Allow this module to manage S3 itself. If true, 
#   All other s3 parameters are ignored.
#
# @param [String[1]] $hdp_s3_endpoint
#   The S3 Endpoint to use
#
# @param [String[1]] $hdp_s3_region
#   The S3 Region to use 
#
# @param [String[1]] $hdp_s3_access_key = 'puppet',
#   The S3 Access Key to use
#
# @param [String[1]] $hdp_s3_secret_key,
#   The S3 Secret Key to use
#
# @param [String[1]] $hdp_s3_facts_bucket,
#   The S3 Bucket to use for facts
#
# @param [Boolean] $hdp_s3_force_path_style,
#   Disable AWS specific S3 Path Style
#
# @param [Boolean] $hdp_s3_disable_ssl,
#   Disable SSL for the S3 backend 
#
# @param [String] hdp_user
#   User to run HDP + all infra services as. Also owns mounted volumes
#   Set to Puppet if certname == dns_name
#
# @param [String] hdp_user
#   
# @param [String] compose_version
#   The version of docker-compose to install
#
# @param [Optional[String[1]]] image_repository
#   Image repository to pull images from - defaults to dockerhub.
#   Can be used for airgapped environments/testing environments
#
# @param [String[1]] image_prefix
#   Prefix that comes before each image
#   Can be used for easy name spacing under the same repository
#
# @param [Optional[String[1]]] ca_server
#   URL of Puppet CA Server. If no keys/certs are provided, then 
#   HDP will attempt to provision its own certs and get them signed.
#   Either this or ca_cert_file/key_file/cert_file can be specified.
#   If autosign is not enabled, HDP will wait for the certificate to be signed
#   by a puppet administrator
#
# @param [Optional[String[1]]] ca_cert_file
#   CA certificate to validate connecting clients
#   This or ca_server can be specified
#
# @param [Optional[String[1]]] key_file
#   Private key for cert_file - pem encoded.
#   This or ca_server can be specified
#
# @param [Optional[String]] cert_file
#   Puppet PKI cert file - pem encoded.
#   This or ca_server can be specified
#
# @param [Boolean] ui_use_tls
#   Use TLS for the UI and HDP Query endpoints
#
# @param [Optional[String]] ui_key_file
#   Key file to use for UI - pem encoded.
#   Your browser should trust this you set ui_use_tls
#   
# @param [Optional[String]] ui_cert_file
#   Cert file to use for UI - pem encoded.
#   Your browser should trust this you set ui_use_tls
#
# @param [Optional[String]] ui_ca_cert_file
#   CA Cert file to use for UI - pem encoded.
#   Your browser should have key to access this if you want to set it
#   Set this to not undef to protect this endpoint.
#
# @param [String[1]] dns_name
#   Name that puppet server will find HDP at.
#   Should match the names in cert_file if provided.
#   If ca_server is used instead, this name will be used as certname.
#
# @param [Array[String[1]]] dns_alt_names
#   Extra dns names attached to the puppet cert, can be used to bypass certname collisions
#
# @param [String[1]] hdp_version
#   The version of the HDP containers to use
#
# @param [String[1]] hdp_version
#   The version of the HDP containers to use
#
# @param [String[1]] log_driver
#   The log driver Docker will use
#
# @param [Optional[Array[String[1]]] docker_users
#   Users to be added to the docker group on the system
#
# @param [String[1]] max_es_memory
#   Max memory for ES to use - in JVM -Xmx{$max_es_memory} format.
#   Example: 4G, 1024M. Defaults to 4G.
#
# @example Use defalts or configure via Hiera
#   include hdp::app_stack
#
# @example Manage the docker group elsewhere
#   realize(Group['docker'])
#
#   class { 'hdp::app_stack':
#     create_docker_group => false,
#     require             => Group['docker'],
#   }
#
class hdp::app_stack (
  String[1] $dns_name,
  Array[String[1]] $dns_alt_names = [],

  Boolean $create_docker_group = true,
  Boolean $manage_docker = true,
  Optional[Array[String[1]]] $docker_users = undef,
  Integer $hdp_port = 9091,
  Integer $hdp_ui_port = 80,
  Integer $hdp_query_port = 9092,
  String[1] $hdp_user = '11223',
  String[1] $compose_version = '1.25.0',
  Optional[String[1]] $image_repository = undef,

  ## Either one of these two options can be configured
  Optional[String[1]] $ca_server = undef,

  Optional[String[1]] $ca_cert_file = undef,
  Optional[String[1]] $key_file = undef,
  Optional[String[1]] $cert_file = undef,


  Boolean $ui_use_tls = false,
  Optional[String[1]] $ui_ca_cert_file = undef,
  Optional[String[1]] $ui_key_file = undef,
  Optional[String[1]] $ui_cert_file = undef,

  Boolean $hdp_manage_es = true,
  String[1] $hdp_es_host = 'http://elasticsearch:9200/',
  Optional[String[1]] $hdp_es_username = undef,
  Optional[String[1]] $hdp_es_password = undef,

  Boolean $hdp_manage_s3 = true,
  String[1] $hdp_s3_endpoint = 'http://minio:9000/',
  String[1] $hdp_s3_region = 'hdp',
  String[1] $hdp_s3_access_key = 'puppet',
  String[1] $hdp_s3_secret_key = 'puppetpuppet',
  String[1] $hdp_s3_facts_bucket = 'facts',
  Boolean $hdp_s3_force_path_style = true,
  Boolean $hdp_s3_disable_ssl = true,

  String[1] $image_prefix = 'puppet/hdp-',
  String[1] $hdp_version = '0.0.1',
  String[1] $log_driver = 'journald',
  String[1] $max_es_memory = '4G',
){
  if $create_docker_group {
    ensure_resource('group', 'docker', {'ensure' => 'present'})
  }

  if $manage_docker {
    class { 'docker':
      docker_users => $docker_users,
      log_driver   => $log_driver,
    }

    class { 'docker::compose':
      ensure  => present,
      version => $compose_version,
    }
  }

  $mount_host_certs=$trusted['certname'] == $dns_name
  if $mount_host_certs {
    $_final_hdp_user=String[1]($facts['hdp_health']['puppet_user'])
  } else {
    $_final_hdp_user=$hdp_user
  }

  if $hdp_manage_es {
    $_final_hdp_es_username=undef
    $_final_hdp_es_password=undef
    $_final_hdp_es_host="http://elasticsearch:9200/"
  } else {
    $_final_hdp_es_username=$hdp_es_username
    $_final_hdp_es_password=$hdp_es_password
    $_final_hdp_es_host=$hdp_es_host
  }

  $_final_hdp_s3_access_key=$hdp_s3_access_key
  $_final_hdp_s3_secret_key=$hdp_s3_secret_key
  if $hdp_manage_s3 {
    $_final_hdp_s3_endpoint='http://minio:9000/'
    $_final_hdp_s3_region='hdp'
    $_final_hdp_s3_facts_bucket='facts'
    $_final_hdp_s3_disable_ssl=true
    $_final_hdp_s3_force_path_style=true
  } else {
    $_final_hdp_s3_endpoint=$hdp_s3_endpoint
    $_final_hdp_s3_region=$hdp_s3_region
    $_final_hdp_s3_facts_bucket=$hdp_s3_facts_bucket
    $_final_hdp_s3_disable_ssl=$hdp_s3_disable_ssl
    $_final_hdp_s3_force_path_style=$hdp_s3_force_path_style
  }

  file {
    default:
      owner   => 'root',
      group   => 'docker',
      require => Group['docker'],
    ;
    '/opt/puppetlabs/hdp':
      ensure => directory,
      mode   => '0775',
      owner  => $_final_hdp_user,
      group  => $_final_hdp_user,
    ;
    '/opt/puppetlabs/hdp/ssl':
      ensure => directory,
      mode   => '0700',
      owner  => $_final_hdp_user,
      group  => $_final_hdp_user,
    ;
    '/opt/puppetlabs/hdp/redis':
      ensure => directory,
      mode   => '0700',
      owner  => $_final_hdp_user,
      group  => $_final_hdp_user,
    ;
    '/opt/puppetlabs/hdp/docker-compose.yaml':
      ensure  => file,
      mode    => '0440',
      content => epp('hdp/docker-compose.yaml.epp', {
        'hdp_version'             => $hdp_version,
        'image_prefix'            => $image_prefix,
        'image_repository'        => $image_repository,
        'hdp_port'                => $hdp_port,
        'hdp_ui_port'             => $hdp_ui_port,
        'hdp_query_port'          => $hdp_query_port,

        'hdp_manage_s3'           => $hdp_manage_s3,
        'hdp_s3_endpoint'         => $_final_hdp_s3_endpoint,
        'hdp_s3_region'           => $_final_hdp_s3_region,
        'hdp_s3_access_key'       => $_final_hdp_s3_access_key,
        'hdp_s3_secret_key'       => $_final_hdp_s3_secret_key,
        'hdp_s3_disable_ssl'      => $_final_hdp_s3_disable_ssl,
        'hdp_s3_facts_bucket'     => $_final_hdp_s3_facts_bucket,
        'hdp_s3_force_path_style' => $_final_hdp_s3_force_path_style,

        'hdp_manage_es'           => $hdp_manage_es,
        'hdp_es_host'             => $_final_hdp_es_host,
        'hdp_es_username'         => $_final_hdp_es_username,
        'hdp_es_password'         => $_final_hdp_es_password,

        'ca_server'               => $ca_server,
        'key_file'                => $key_file,
        'cert_file'               => $cert_file,
        'ca_cert_file'            => $ca_cert_file,

        'ui_use_tls'              => $ui_use_tls,
        'ui_key_file'             => $ui_key_file,
        'ui_cert_file'            => $ui_cert_file,
        'ui_ca_cert_file'         => $ui_ca_cert_file,

        'dns_name'                => $dns_name,
        'dns_alt_names'           => $dns_alt_names,
        'hdp_user'                => $_final_hdp_user,
        'root_dir'                => '/opt/puppetlabs/hdp',
        'max_es_memory'           => $max_es_memory,
        'mount_host_certs'        => $mount_host_certs,
      }),
    ;
  }

  ## Elasticsearch container FS is all 1000
  ## While not root, this very likely crashes with something with passwordless sudo on the main host
  ## 100% needs to change when we start deploying our own containers
  if $hdp_manage_es {
    file {
      '/opt/puppetlabs/hdp/elastic':
        ensure => directory,
        mode   => '0700',
        owner  => 1000,
        group  => 1000,
      ;
    }
  }

  if $hdp_manage_s3 {
    file {
      '/opt/puppetlabs/hdp/minio':
        ensure => directory,
        mode   => '0700',
        owner  => $_final_hdp_user,
        group  => $_final_hdp_user,
      ;
      '/opt/puppetlabs/hdp/minio/data':
        ensure => directory,
        mode   => '0700',
        owner  => $_final_hdp_user,
        group  => $_final_hdp_user,
      ;
      "/opt/puppetlabs/hdp/minio/data/${hdp_s3_facts_bucket}":
        ensure => directory,
        mode   => '0700',
        owner  => $_final_hdp_user,
        group  => $_final_hdp_user,
      ;
      '/opt/puppetlabs/hdp/minio/config':
        ensure => directory,
        mode   => '0700',
        owner  => $_final_hdp_user,
        group  => $_final_hdp_user,
      ;
    }
  }


  docker_compose { 'hdp':
    ensure        => present,
    compose_files => [ '/opt/puppetlabs/hdp/docker-compose.yaml', ],
  }
}
