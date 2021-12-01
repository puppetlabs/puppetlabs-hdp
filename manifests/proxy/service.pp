# @api private
class hdp::proxy::service {
  docker_compose { 'hdp-proxy':
    ensure        => present,
    compose_files => ['/opt/puppetlabs/hdp/proxy/docker-compose.yaml',],
    require       => File['/opt/puppetlabs/hdp/proxy/docker-compose.yaml'],
    subscribe     => File['/opt/puppetlabs/hdp/proxy/docker-compose.yaml'],
  }
}
