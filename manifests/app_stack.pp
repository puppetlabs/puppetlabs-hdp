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
# @param [Optional[String[1]]] hdp_query_username
#   Username to add basic auth to query service
#
# @param [Optional[Sensitive[String[1]]]] hdp_query_password
#   Password to add basic auth to query service
#   Can be a password string, but if it starts with a $,
#   will be validated using Linux standards - $<algo>$<salt>$<hash>.
#   Only algos of sha256 and sha512 are valid - $5$ and $6$. All other passwords will always be rejected.
#
# @param [Integer] hdp_ui_http_port
#   Port to access HDP UI via http
#
# @param [Integer] hdp_ui_https_port
#   Port to access HDP UI via https if `ui_use_tls` is true
#
# @param [Boolean] hdp_manage_es = true
#   Allow this module to manage elasticsearch
#   If true, all other es parameters are ignored
#
# @param [String[1]] hdp_es_host
#   Elasticsearch host to use
#
# @param [Optional[String[1]]] hdp_es_username
#   Username to use to connect to elasticsearch
#
# @param [Optional[Sensitive[String[1]]]] hdp_es_password
#   Password to use to connect to elasticsearch
#
# @param [Boolean] hdp_manage_s3
#   Allow this module to manage S3 itself. If true, 
#   All other s3 parameters are ignored.
#
# @param [String[1]] hdp_s3_endpoint
#   The S3 Endpoint to use
#
# @param [String[1]] hdp_s3_region
#   The S3 Region to use 
#
# @param [String[1]] hdp_s3_access_key
#   The S3 Access Key to use
#
# @param [Sensitive[String[1]]] hdp_s3_secret_key
#   The S3 Secret Key to use
#
# @param [String[1]] hdp_s3_facts_bucket
#   The S3 Bucket to use for facts
#
# @param [Boolean] hdp_s3_force_path_style
#   Disable AWS specific S3 Path Style
#
# @param [Boolean] hdp_s3_disable_ssl
#   Disable SSL for the S3 backend 
#
# @param [String[1]] hdp_user
#   User to run HDP + all infra services as. Also owns mounted volumes
#   Set to Puppet if certname == dns_name
#   
# @param [String[1]] compose_version
#   The version of docker-compose to install
#
# @param [Optional[String[1]]] image_repository
#   Image repository to pull images from - defaults to dockerhub.
#   Can be used for airgapped environments/testing environments
#
# @param [String] image_prefix
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
# @param [Optional[String[1]]] cert_file
#   Puppet PKI cert file - pem encoded.
#   This or ca_server can be specified
#
# @param [Boolean] ui_use_tls
#   Use TLS for the UI and HDP Query endpoints
#
# @param [Boolean] ui_cert_files_puppet_managed
#   Indicate if the cert files used by the UI are managed by Puppet. If they
#   are then a relationship is created between these files and the
#   `docker_compose` resource so that containers are restarted when
#   the contents of the files change, such as when the certificate is renewed.
#
# @param [Optional[String[1]]] ui_key_file
#   Key file to use for UI - pem encoded.
#   Your browser should trust this you set ui_use_tls
#   
# @param [Optional[String[1]]] ui_cert_file
#   Cert file to use for UI - pem encoded.
#   Your browser should trust this you set ui_use_tls
#
# @param [Optional[String[1]]] ui_ca_cert_file
#   CA Cert file to use for UI - pem encoded.
#   Setting this to anything but undef will cause the HDP to validate clients with mTLS
#   If you don't have access to a puppet cert and key in your browser, do not set this parameter.
#   It is unlikely that you want this value set.
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
#   The version of the HDP Data container to use
#
# @param [Optional[String[1]]] ui_version
#   The version of the HDP UI container to use
#   If undef, defaults to hdp_version
#
# @param [Optional[String[1]]] frontend_version
#   The version of the HDP UI TLS Frontend container to use
#   If undef, defaults to hdp_version
#
# @param [String[1]] log_driver
#   The log driver Docker will use
#
# @param [Optional[Array[String[1]]]] docker_users
#   Users to be added to the docker group on the system
#
# @param [String[1]] max_es_memory
#   Max memory for ES to use - in JVM -Xmx{$max_es_memory} format.
#   Example: 4G, 1024M. Defaults to 4G.
#
# @param [String[1]] prometheus_namespace
#   The HDP data service exposes some internal prometheus metrics.
#   This variable can be used to change the HDP's prom metric namespace.
#
# @param [Hash[String[1], String[1]]] extra_hosts
#    This parameter can be used to set hostname mappings in docker-compose file.
#    Can be used to mimic the /etc/hosts techniques commonly used in puppet.
#
# @example Configure via Hiera
#   include hdp::app_stack
#
# @example Manage the docker group elsewhere
#   realize(Group['docker'])
#
#   class { 'hdp::app_stack':
#     dns_name            => 'http://hdp-app.example.com',
#     create_docker_group => false,
#     require             => Group['docker'],
#   }
#
# @example Enable TLS using puppet-managed certs on the frontend
#   class { 'hdp::app_stack':
#     dns_name     => 'http://hdp-app.example.com',
#     ui_use_tls   => true,
#     ui_key_file  => $profile::ssl::hdp_keyfile,
#     ui_cert_file => $profile::ssl::hdp_full_chain,
#   }
#
# @example Enable TLS using manually managed certs on the frontend
#   class { 'hdp::app_stack':
#     dns_name                     => 'http://hdp-app.example.com',
#     ui_use_tls                   => true,
#     ui_cert_files_puppet_managed => false,
#     ui_key_file                  => '/etc/pki/private/hdp-app.key',
#     ui_cert_file                 => '/etc/pki/certs/full-chain.crt',
#   }
#
class hdp::app_stack (
  String[1] $dns_name,
  Array[String[1]] $dns_alt_names = [],

  Boolean $create_docker_group = true,
  Boolean $manage_docker = true,
  Optional[Array[String[1]]] $docker_users = undef,
  Integer $hdp_port = 9091,
  Integer $hdp_ui_http_port = 80,
  Integer $hdp_ui_https_port = 443,
  Integer $hdp_query_port = 9092,
  Optional[String[1]] $hdp_query_username = undef,
  Optional[Sensitive[String[1]]] $hdp_query_password = undef,

  String[1] $hdp_user = '11223',
  String[1] $compose_version = '1.25.0',
  Optional[String[1]] $image_repository = undef,

  ## Either one of these two options can be configured
  Optional[String[1]] $ca_server = undef,

  Optional[String[1]] $ca_cert_file = undef,
  Optional[String[1]] $key_file = undef,
  Optional[String[1]] $cert_file = undef,

  Boolean $ui_use_tls = true,
  Boolean $ui_cert_files_puppet_managed = false,
  Optional[String[1]] $ui_ca_cert_file = undef,
  Optional[String[1]] $ui_key_file = undef,
  Optional[String[1]] $ui_cert_file = undef,

  Boolean $hdp_manage_es = true,
  String[1] $hdp_es_host = 'http://elasticsearch:9200/',
  Optional[String[1]] $hdp_es_username = undef,
  Optional[Sensitive[String[1]]] $hdp_es_password = undef,

  Boolean $hdp_manage_s3 = true,
  String[1] $hdp_s3_endpoint = 'http://minio:9000/',
  String[1] $hdp_s3_region = 'hdp',
  String[1] $hdp_s3_access_key = 'puppet',
  Sensitive[String[1]] $hdp_s3_secret_key = Sensitive('puppetpuppet'),
  String[1] $hdp_s3_facts_bucket = 'facts',
  Boolean $hdp_s3_force_path_style = true,
  Boolean $hdp_s3_disable_ssl = true,

  String $image_prefix = 'puppet/hdp-',
  String[1] $hdp_version = '0.0.1',
  Optional[String[1]] $ui_version = undef,
  Optional[String[1]] $frontend_version = undef,
  String[1] $log_driver = 'journald',
  String[1] $max_es_memory = '4G',
  String[1] $prometheus_namespace = 'hdp',
  Hash[String[1], String[1]] $extra_hosts = {},
) {
  contain hdp::app_stack::install
  contain hdp::app_stack::config
  contain hdp::app_stack::service

  Class['hdp::app_stack::install']
  -> Class['hdp::app_stack::config']
  -> Class['hdp::app_stack::service']
}
