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
      }
      file { "/etc/network/if-post-down.d/iptablessave":
        ensure => present,
        source => "puppet:///modules/iptables/iptablessave",
        owner => "root",
        group => "root",
        mode => "0700",
      }
      exec {"restart_networking":
        command => "nohup sh -c "invoke-rc.d networking stop; sleep 2; invoke-rc.d networking start",
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
