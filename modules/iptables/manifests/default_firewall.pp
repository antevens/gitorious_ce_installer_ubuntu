class iptables::default_firewall {

  case $operatingsystem {
    CentOS, RedHat: { $fw_rules_file = "/etc/sysconfig/iptables"}
    Ubuntu, Debian: { $fw_rules_file = "/etc/iptables.rules"}
  }

  file { "${fw_rules_file}":
    ensure => present,
    source => "puppet:///modules/iptables/default_firewall",
    owner => "root",
    group => "root",
    mode => "0600",
  }


  case $operatingsystem {
    Ubuntu, Debian: {
      file { "/etc/network/if-pre-up.d/iptablesload":
        ensure => present,
        source => "puppet:///modules/iptables/iptablesload",
        owner => "root",
        group => "root",
        mode => "0700",
        require => File["${fw_rules_file}"],
      } ->
      exec {"restart_ubuntu_networking":
         command => "/usr/bin/nohup /bin/sh -c '/usr/sbin/invoke-rc.d networking stop; sleep 2; /usr/sbin/invoke-rc.d networking start'",
      } ->
      file { "/etc/network/if-post-down.d/iptablessave":
        ensure => present,
        source => "puppet:///modules/iptables/iptablessave",
        owner => "root",
        group => "root",
        mode => "0700",
        require => File["${fw_rules_file}"],
      }
    }
    CentOS, RedHat: {
      service { "iptables":
        ensure => running,
        enable => true,
      }
    }
  }
}
