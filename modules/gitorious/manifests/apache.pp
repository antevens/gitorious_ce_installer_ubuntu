class gitorious::apache {
  Exec { path => ["/opt/ruby-enterprise/bin","/usr/local/bin","/usr/bin","/bin", "/usr/sbin"] }

  case $operatingsystem {
    CentOS, RedHat: { $package_list = ["httpd","httpd-devel","apr-devel","apr-util-devel","mod_ssl"],
              $web_server_dir = "/etc/httpd"
              $web_confd_dir = "${web_server_dir}/conf.d",
              $web_module_dir = "${web_server_dir}/modules"}
    Ubuntu, Debian: { $package_list = ["apache2","apache2-dev","libapr1","libapr1-dev","libapr-memcache0","libapr-memcache0-dev","mod_ssl"] }
              $web_server_dir = "/etc/apache2" 
              $web_confd_dir = "${web_server_dir}/conf.d",
              $web_module_dir = "${web_server_dir}/available-modules}
 }

  package { $package_list: ensure => installed }

  service { "web-server":
    name => $operatingsystem ? {
      Centos => "httpd",
      RedHat => "httpd",
      Ubuntu => "apache2",
    },
    enable => true,
    ensure => running,
    subscribe => File["${web_confd_dir}/passenger.conf"],
    require => Exec["install_xsendfile"],
  }
  case $operatingsystem {
    Centos, Redhat: {
      exec {"install_passenger_module":
        command => "passenger-install-apache2-module -a && touch /opt/passenger_installed",
        creates => "/opt/passenger_installed",
        require => Exec["install_our_passenger"],
      }
    }
   Ubuntu, Debian: {
     package { libapache2-mod-passenger: ensure => installed}
   }
 }

  exec {"install_our_passenger":
    command => "gem install --no-ri --no-rdoc -v '${gitorious::passenger_version}' passenger",
    creates => "/usr/lib/ruby/gems/1.8/gems/passenger-${gitorious::passenger_version}",
    require => Package["mod_ssl","httpd-devel","apr-devel","apr-util-devel"],
  }

  file {"/etc/httpd/conf.d/passenger.conf":
    require => Exec["install_passenger_module"],
    owner => "root",
    group => "root",
    source => "puppet:///modules/gitorious/apache/passenger.conf",
  }

  file {"/etc/httpd/conf.d/ssl.conf":
    ensure => absent,
  }

  exec {"install_xsendfile":
    command => "/bin/sh -c 'cd /tmp && wget --no-check-certificate https://tn123.org/mod_xsendfile/mod_xsendfile.c && apxs -cia mod_xsendfile.c'",
    creates => "/etc/httpd/modules/mod_xsendfile.so",
    require => Package["httpd-devel"],
  }

  define vhost($server_name, $certificate_file="/etc/pki/tls/certs/localhost.crt", $certificate_key_file="/etc/pki/tls/private/localhost.key", $certificate_ca_chain="") {
    $file = "/etc/httpd/conf.d/gitorious.vhost.conf"

    $document_root = "${gitorious::app_root}/public"
    $repository_root = $gitorious::repository_root
    $tarballs_cache = $gitorious::tarballs_cache

    file {$file:
      ensure => present,
      owner => "root",
      group => "root",
      notify => Service["httpd"],
      content => template("gitorious/gitorious.vhost.conf.erb"),
      require => Package["httpd"],
    }
  }

  # A virtual host with real SSL certs. These *must* be inside the puppet repo
  define vhost_with_real_certs($server_name, $customer_name) {
    $cert = "/etc/pki/tls/certs/${name}.crt"
    $key = "/etc/pki/tls/private/${name}.key"
    $ca_chain = "/etc/pki/tls/${name}_ca_chain.crt"

    gitorious::apache::vhost {$server_name:
      server_name => $server_name,
      certificate_file => $cert,
      certificate_key_file => $key,
      certificate_ca_chain => $ca_chain,
    }
    file { $cert:
      ensure => present,
      owner => root,
      group => root,
      mode => "0600",
      source => "puppet:///modules/gitorious/ssl/clients/$customer_name/${name}.crt",
    }
    file { $key:
      ensure => present,
      owner => root,
      group => root,
      mode => "0600",
      source => "puppet:///modules/gitorious/ssl/clients/$customer_name/${name}.key",
    }
    file { $ca_chain:
      ensure => present,
      owner => root,
      group => root,
      mode => "0600",
      source => "puppet:///modules/gitorious/ssl/clients/$customer_name/${name}_ca_chain.crt",
    }
  }

}
