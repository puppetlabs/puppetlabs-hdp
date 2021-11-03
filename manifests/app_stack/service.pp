# @api private
class hdp::app_stack::service {
  docker_compose { 'hdp':
    ensure        => present,
    compose_files => ['/opt/puppetlabs/hdp/docker-compose.yaml',],
    require       => File['/opt/puppetlabs/hdp/docker-compose.yaml'],
    subscribe     => File['/opt/puppetlabs/hdp/docker-compose.yaml'],
  }
}
