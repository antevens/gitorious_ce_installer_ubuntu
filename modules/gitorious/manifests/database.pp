class gitorious::database {

  Exec { path => ["/usr/local/bin","/usr/bin","/bin"] }

  case $operatingsystem {
    "CentOS", "RedHat": { 
        $package_list = ["mysql", "mysql-devel", "mysql-server"]
        $mysql_service_name = "mysqld"
    }
    "Ubuntu", "Debian": {
        $package_list = ["mysql-server", "libmysqld-dev", "libmysqlclient-dev"]
        $mysql_service_name = "mysql"
    }
  }

  package { $package_list: ensure => installed }

  service { "mysql":
    name => "${mysql_service_name}",
    ensure => running,
    enable => true,
    require => Package[$package_list]
  }

  mysql::create_database { "gitorious_production":
    username => "gitorious",
    password => "0abced070e846b7a73d067a37808115612ca06f9",
  }

  file {"db_seed":
    path => "${gitorious::app_root}/db/seeds.rb",
    ensure => present,
    source => "puppet:///modules/gitorious/config/seeds.rb",
    owner => "git",
    group => "git",
    require => File["/usr/local/bin/gitorious"],
  }

  $bundler_version = "1.2.2"

  exec { "install_bundler":
    command => "gem install --no-ri --no-rdoc -v '$bundler_version' bundler",
    creates => "${gem_path}/bundler-$bundler_version",
    require => [Package[$package_list], Exec["clone_gitorious_source"]],
  }

  exec {"bundle_install":
    command => "/bin/sh -c 'env BUNDLE_GEMFILE=${gitorious::app_root}/Gemfile bundle install && touch ${gitorious::app_root}/tmp/bundles_installed'",
    require => File["bundler_config_file"],
    creates => "${gitorious::app_root}/tmp/bundles_installed",
  }

  file {"bundler_config_home":
    path => "${gitorious::app_root}/.bundle",
    require => Exec["install_bundler"],
    ensure => directory,
    owner => "git",
    group => "git",
    mode => "0755",
  }

  file {"bundler_config_file":
    path => "${gitorious::app_root}/.bundle/config",
    require => File["bundler_config_home"],
    ensure => present,
    owner => "git",
    group => "git",
    mode => "0644",
    source => "puppet:///modules/gitorious/bundler_config",
  }

  exec {"populate_database":
    command => "${gitorious::app_root}/bin/rake db:setup && touch ${gitorious::app_root}/tmp/database_populated",
    creates => "${gitorious::app_root}/tmp/database_populated",
    require => [
                File["db_seed"],
                Mysql::Create_database["gitorious_production"],
                Exec["bundle_install"],
                ],
  }

}
