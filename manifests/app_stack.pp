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
#   defaults to 9091
#
# @param [Integer] hdp_query_port
#   Port to access HDP query service
#   defaults to 8080
#
# @param [Integer] hdp_ui port
#   Port to access HDP UI
#   defaults to 80
#
# @param String hdp_user
#   User to run HDP + all infra services as. Also owns mounted volumes
#   Set to Puppet if certname == dns_name
#   
# @param String compose_version
#   The version of docker-compose to install
#
# @param Optional[String] image_repository
#   Image repository to pull images from - defaults to dockerhub.
#   Can be used for airgapped environments/testing environments
#
# @param String image_prefix
#   Prefix that comes before each image
#   Can be used for easy name spacing under the same repository
#
# @param Optional[String] ca_server
#   URL of Puppet CA Server. If no keys/certs are provided, then 
#   HDP will attempt to provision its own certs and get them signed.
#   Either this or ca_cert_file/key_file/cert_file can be specified.
#   If autosign is not enabled, HDP will wait for the certificate to be signed
#   by a puppet administrator
#
# @param Optional[String] ca_cert_file
#   CA certificate to validate connecting clients
#   This or ca_server can be specified
#
# @param Optional[String] key_file
#   Private key for cert_file - pem encoded.
#   This or ca_server can be specified
#
# @param Optional[String] cert_file
#   Puppet PKI cert file - pem encoded.
#   This or ca_server can be specified
#
# @param String dns_name
#   Name that puppet server will find HDP at.
#   Should match the names in cert_file if provided.
#   If ca_server is used instead, this name will be used as certname.
#
# @param String dns_alt_names
#   Extra dns names attached to the puppet cert, can be used to bypass certname collisions
#
# @param String hdp_version
#   The version of the HDP containers to use
#
# @param String hdp_version
#   The version of the HDP containers to use
#
# @param String log_driver
#   The log driver Docker will use
#
# @param [Optional[ArrayString]] docker_users
#   Users to be added to the docker group on the system
#
# @param String max_es_memory
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
  Boolean $create_docker_group = true,
  Boolean $manage_docker = true,
  Integer $hdp_port = 9091,
  Integer $hdp_ui_port = 80,
  Integer $hdp_query_port = 8080,
  String $hdp_user = '11223',
  String $compose_version = '1.25.0',
  Optional[String] $image_repository = undef,

  ## Either one of these two options can be configured
  Optional[String] $ca_server = undef,

  Optional[String] $ca_cert_file = undef,
  Optional[String] $key_file = undef,
  Optional[String] $cert_file = undef,

  String $dns_name = 'hdp.puppet',
  Array[String] $dns_alt_names = [],

  String $image_prefix = 'puppet/hdp-',
  String $hdp_version = '0.0.1',
  String $log_driver = 'journald',
  String $max_es_memory = '4G',
  Optional[Array[String]] $docker_users = undef,
){
  if $create_docker_group {
    ensure_resource('group', 'docker', {'ensure' => 'present' })
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
    $final_hdp_user=String($facts['hdp_health']['puppet_user'])
  } else {
    $final_hdp_user=$hdp_user
  }

  file {
    default:
      owner   => 'root',
      group   => 'docker',
      require => Group['docker'],
      before  => Docker_compose['hdp'],
    ;
    '/opt/puppetlabs/hdp':
      ensure => directory,
      mode   => '0775',
      owner  => $final_hdp_user,
      group  => $final_hdp_user,
    ;
    '/opt/puppetlabs/hdp/ssl':
      ensure => directory,
      mode   => '0700',
      owner  => $final_hdp_user,
      group  => $final_hdp_user,
    ;
    ## Elasticsearch container FS is all 1000
    ## While not root, this very likely crashes with something with passwordless sudo on the main host
    ## 100% needs to change when we start deploying our own containers
    '/opt/puppetlabs/hdp/elastic':
      ensure => directory,
      mode   => '0700',
      owner  => 1000,
      group  => 1000,
    ;
    '/opt/puppetlabs/hdp/redis':
      ensure => directory,
      mode   => '0700',
      owner  => $final_hdp_user,
      group  => $final_hdp_user,
    ;
    '/opt/puppetlabs/hdp/docker-compose.yaml':
      ensure  => file,
      mode    => '0440',
      content => epp('hdp/docker-compose.yaml.epp', {
        'hdp_version'      => $hdp_version,
        'image_prefix'     => $image_prefix,
        'image_repository' => $image_repository,
        'hdp_port'         => $hdp_port,
        'hdp_ui_port'      => $hdp_ui_port,
        'hdp_query_port'   => $hdp_query_port,
        'ca_server'        => $ca_server,
        'key_file'         => $key_file,
        'cert_file'        => $cert_file,
        'ca_cert_file'     => $ca_cert_file,
        'dns_name'         => $dns_name,
        'dns_alt_names'    => $dns_alt_names,
        'hdp_user'         => $final_hdp_user,
        'root_dir'         => '/opt/puppetlabs/hdp',
        'max_es_memory'    => $max_es_memory,
        'mount_host_certs' => $mount_host_certs,
      }),
    ;
  }

  docker_compose { 'hdp':
    ensure        => present,
    compose_files => [ '/opt/puppetlabs/hdp/docker-compose.yaml', ],
  }
}
