# @api private
class hdp::app_stack::install () {
  if $hdp::app_stack::create_docker_group and $hdp::app_stack::manage_docker {
    group { 'docker':
      ensure => 'present',
      before => Class['docker'],
    }
  }

  if $hdp::app_stack::manage_docker {
    class { 'docker':
      docker_users => $hdp::app_stack::docker_users,
      log_driver   => $hdp::app_stack::log_driver,
      root_dir     => $hdp::app_stack::data_dir,
    }
    -> class { 'docker::compose':
      ensure  => present,
      version => $hdp::app_stack::compose_version,
    }
  }
}
