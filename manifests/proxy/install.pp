# @api private
class hdp::proxy::install () {
  if $hdp::proxy::create_docker_group {
    group { 'docker':
      ensure => 'present',
      before => Class['docker'],
    }
  }

  if $hdp::proxy::manage_docker {
    class { 'docker':
      docker_users => $hdp::proxy::docker_users,
      log_driver   => $hdp::proxy::log_driver,
    }
    -> class { 'docker::compose':
      ensure  => present,
      version => $hdp::proxy::compose_version,
    }
  }
}
