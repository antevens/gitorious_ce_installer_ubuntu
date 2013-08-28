class gitorious::dependencies {

  # Default path
  Exec { path => ["/opt/ruby-enterprise/bin","/usr/local/bin","/usr/bin","/bin", "/usr/sbin"] }

  case $operatingsystem {
    CentOS: {       case $operatingsystemrelease {
        /^5/: {
          $package_list = ["monit", "memcached", "ImageMagick","gcc-c++","zlib-devel","make","wget","libxml2","libxml2-devel","libxslt","libxslt-devel","gcc", "ruby-devel", "openssl", "curl-devel"]
        }
        default: {
          $package_list = ["monit", "memcached", "ImageMagick","gcc-c++","zlib-devel","make","wget","libxml2","libxml2-devel","libxslt","libxslt-devel","gcc", "ruby-devel", "openssl", "libcurl-devel"]
        }
      }
    }
    Ubuntu: { $package_list = ["monit", "memcached", "imagemagick","gobjc++","libghc-zlib-dev","make","wget","libxml2","libxml2-dev","libxslt1.1","libxslt1-dev","gcc", "ruby-dev", "openssl", "libcurl4-openssl-dev"]}
  }

  package { $package_list: ensure => installed }

  service { "memcached":
    enable => true,
    ensure => running,
    require => Package["memcached"],
  }

  service {"monit":
    enable => true,
    ensure => running,
    require => [
                Package["monit"],
                File["/etc/gitorious.conf"],
                ],
  }

  file {"/etc/monit.conf":
    ensure => present,
    owner => "root",
    group => "root",
    mode => "0600",
    source => "puppet:///modules/gitorious/config/monit.conf",
    require => Package["monit"],
  }

}
