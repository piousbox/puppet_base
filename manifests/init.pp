
class puppet_base {

  #
  # variables
  #

  $timeservers = [ '0.pool.ntp.org', '1.pool.ntp.org' ]
  $snmp = { rocommunity => 'public',
    sysDescr => 'NexentaOS',
    sysLocation => '', 
    sysContact => 'youremail@me.com', 
    trapsink => 'localhost', 
    linkUpDownNofitications => 'yes', 
    master => 'agentx', 
    extends => [],
  }
  $nameservers = [ '10.2.3.4', '10.2.3.5' ]
  $resolv_search = 'mgt.yourcompany.net prd.yourcompany.net'
  $domainname = $hostname
  $loghosts = [ 'loghost1', 'loghost2' ]

  # defaults -- except nfs_server_versmax where default is 4,
  # and nfs_client_versmax where default is 4
  $nfs = { nfsd_listen_backlog => '64', 
    nfsd_protocol => 'ALL', 
    nfsd_servers => '1024', 
    lockd_listen_backlog => '64', 
    lockd_servers => '1024', 
    lockd_retransmit_timeout => '5', 
    grace_pediod => '90', 
    nfs_server_versmax => '3', 
    nfs_client_versmax => '3',
  }
  $zfs_resilver_delay = '2' # default
  $zfs_txg_synctime_ms = '5000' # default
  $zfs_txg_timeout = '10' # default

  # non-default
  $system_extra = { swapfs_minfree => '1048576',
    'zfs:l2arc_write_boost' => '83886080',
  } 
  $authorized_keys = [ 'ssh-dss AAAA...== joe', 'ssh-dss AAAnasdfg...= jane' ]

  $nms = { ses_check_flapping_default => '2', # between 0 and 9.
    nms_reporter_default => 'disable',
  }
  $logadm = { mnv_log_rotate_default => '10m' } # must be in the XXm format.
  

  #
  # //////////////////////////////////////////////////////////////////////////
  #

  exec { 'restart_ntp':
    command => 'svcadm refresh ntp',
    path => '/',
  }

  exec { 'restart_snmp':
    command => 'svcadm disable snmpd; svcadm enable snmpd',
    path => '/',
  }

  exec { 'restart_syslog':
    command => 'svcadm refresh system-log',
    path => '/',
  }

  exec { 'load_nfs_config':
    command => 'perl -e "use NZA::Common;
                      &NZA::netsvc->reread_config(\'svc:/network/nfs/server:default\');
                      &NZA::netsvc->restart(\'svc:/network/nfs/server:default\');" ',
    path => '/',
  }

  exec { 'enable_nfs':
    command => 'perl -e "use NZA::Common;
                      &NZA::netsvc->enable(\'svc:/network/nfs/server:default\');" ',
    onlyif => $is_nfs_disabled,
    path => '/',
  }

  file { '/etc/nsswitch.conf':
    path => '/etc/nsswitch.conf',
    ensure => present,
    mode => '0644',
    owner => 'root',
    group => 'sys',
    source => 'puppet:///modules/puppet_base/nsswitch.conf',
  }

  file { '/etc/resolv.conf':
    ensure => present,
    mode => '0644',
    owner => 'root',
    group => 'sys',
    content => template('puppet_base/resolv.conf.erb'),
  }

  file { '/kernel/drv/scsi_vhci.conf':
    ensure => present,
    mode => '0644',
    group => 'sys',
    owner => 'root',
    source => 'puppet:///modules/puppet_base/scsi_vhci.conf',
  }

  file { '/etc/syslog.conf':
    ensure => present,
    content => template('puppet_base/syslog.conf.erb'),
    owner => 'root',
    group => 'sys',
    mode => '0644',
    notify => Exec['restart_syslog'],
  }

  file { '/etc/inet/ntp.conf':
    ensure => present,
    content => template('puppet_base/ntp.conf.erb'),
    owner => 'root',
    group => 'sys',
    mode => '0644',
    notify => Exec['restart_ntp'],
  }

  file { '/etc/snmp':
    ensure => directory,
  }

  file { '/etc/snmp/snmpd.conf':
    ensure => file,
    # source => 'puppet:///modules/puppet_base/snmpd.conf.erb',
    content => template('puppet_base/snmpd.conf.erb'),
    owner => 'root',
    group => 'root',
    mode => '0644',
    notify => Exec['restart_snmp'],
  }

  file { '/etc/default/nfs': 
    ensure => file,
    content => template('puppet_base/nfs.erb'),
    owner => 'root',
    group => 'root',
    mode => '0444',
    notify => Exec['load_nfs_config'],
  }

  # block create_nmv_log_attribute

  # block nmv_log_rotate

  # block create_reporter_attribute

  # block change_nms_reporter

  # block create_ses_check_attribute

  # block ses_check_flapping

  file { '/etc/system':
    ensure => present,
    mode => '0755',
    owner => 'root',
    group => 'root',
    content => template('puppet_base/system.erb'),
  }

  file { '/root/.ssh/authorized_keys':
    path => '/root/.ssh/authorized_keys',
    ensure => present,
    mode => '0600',
    owner => 'root',
    group => 'root',
    content => template('puppet_base/authorized_keys.erb'),
  }

  # notify { "hardware platform ${hardware_platform}": }
  # notify { "nexenta version ${nexenta_version}": }
  # notify { "memory in megabytes ${memory_in_megabytes}": }

}