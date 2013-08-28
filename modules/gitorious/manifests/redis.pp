class gitorious::redis {

  case $operatingsystem {
    "CentOS", "RedHat": { 
        $package_list = ["redis"]
        $redis_service_name = "redis"
    }
    "Ubuntu", "Debian": {
        $package_list = ["redis-server"]
        $redis_service_name = "redis-server"
    }
  }

  package { $package_list: ensure => installed }

  service { "redis":
    name => "${redis_service_name}",
    enable => true,
    ensure => running,
    require => Package[$package_list],
  }
}
