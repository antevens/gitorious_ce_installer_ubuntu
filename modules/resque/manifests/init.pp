class resque {
  require gitorious::redis

  $resque_gitorious_root = $gitorious::app_root

  file { "/etc/init/resque-worker.conf":
    ensure => present,
    owner => root,
    group => root,
    content => template("resque/etc/init/resque-worker.conf.erb"),
    require => Service["redis"],
  }
}
