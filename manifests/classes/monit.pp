class monit {

  case $operatingsystem {
    "CentOS", "RedHat": { 
        $monit_confd_dir = "/etc/monit.d"
    }
    "Ubuntu", "Debian": {
        $monit_confd_dir = "/etc/monit/conf.d"
    }
  }

  define config($t_app_root="", $t_control_scripts_dir="", $fqdn=false, $pids_dir="", $pidfile="", $repo_root="") {
    file{"${monit::monit_confd_dir}/${name}.monit":
      ensure => present,
      owner => "root",
      group => "root",
      mode => "0644",
      content => template("gitorious/monit.d/${name}.monit.erb"),
      require => Package["monit"],
      notify => Service["monit"],
    }
  }
}
