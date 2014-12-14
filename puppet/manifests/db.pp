node 'emdb.example.com'  {
  include oradb_os
  include oradb_12c
  include oradb_init
  include oradb_em_agent
}

# operating settings for Database & Middleware
class oradb_os {

  # set the swap
  class { 'swap_file':
    swapfile     => '/var/swap.1',
    swapfilesize => '8192000000'
  }

  # set the tmpfs
  mount { '/dev/shm':
    ensure      => present,
    atboot      => true,
    device      => 'tmpfs',
    fstype      => 'tmpfs',
    options     => 'size=3500m',
  }

  $host_instances = hiera('hosts', {})
  create_resources('host',$host_instances)

  service { iptables:
    enable    => false,
    ensure    => false,
    hasstatus => true,
  }

  $groups = ['oinstall','dba' ,'oper' ]

  group { $groups :
    ensure      => present,
  }

  user { 'oracle' :
    ensure      => present,
    uid         => 500,
    gid         => 'oinstall',
    groups      => $groups,
    shell       => '/bin/bash',
    password    => '$1$DSJ51vh6$4XzzwyIOk6Bi/54kglGk3.',
    home        => "/home/oracle",
    comment     => "This user oracle was created by Puppet",
    require     => Group[$groups],
    managehome  => true,
  }

  $install = ['binutils.x86_64', 'compat-libstdc++-33.x86_64', 'glibc.x86_64','ksh.x86_64','libaio.x86_64',
              'libgcc.x86_64', 'libstdc++.x86_64', 'make.x86_64','compat-libcap1.x86_64', 'gcc.x86_64',
              'gcc-c++.x86_64','glibc-devel.x86_64','libaio-devel.x86_64','libstdc++-devel.x86_64',
              'sysstat.x86_64','unixODBC-devel','glibc.i686','libXext.x86_64','libXtst.x86_64','xorg-x11-xauth']


  package { $install:
    ensure  => present,
  }

  class { 'limits':
    config => {
                '*'       => { 'nofile'  => { soft => '2048'   , hard => '8192',   },},
                'oracle'  => { 'nofile'  => { soft => '65536'  , hard => '65536',  },
                                'nproc'  => { soft => '2048'   , hard => '16384',  },
                                'stack'  => { soft => '10240'  ,},},
                },
    use_hiera => false,
  }

  sysctl { 'kernel.msgmnb':                 ensure => 'present', permanent => 'yes', value => '65536',}
  sysctl { 'kernel.msgmax':                 ensure => 'present', permanent => 'yes', value => '65536',}
  sysctl { 'kernel.shmmax':                 ensure => 'present', permanent => 'yes', value => '2588483584',}
  sysctl { 'kernel.shmall':                 ensure => 'present', permanent => 'yes', value => '2097152',}
  sysctl { 'fs.file-max':                   ensure => 'present', permanent => 'yes', value => '6815744',}
  sysctl { 'net.ipv4.tcp_keepalive_time':   ensure => 'present', permanent => 'yes', value => '1800',}
  sysctl { 'net.ipv4.tcp_keepalive_intvl':  ensure => 'present', permanent => 'yes', value => '30',}
  sysctl { 'net.ipv4.tcp_keepalive_probes': ensure => 'present', permanent => 'yes', value => '5',}
  sysctl { 'net.ipv4.tcp_fin_timeout':      ensure => 'present', permanent => 'yes', value => '30',}
  sysctl { 'kernel.shmmni':                 ensure => 'present', permanent => 'yes', value => '4096', }
  sysctl { 'fs.aio-max-nr':                 ensure => 'present', permanent => 'yes', value => '1048576',}
  sysctl { 'kernel.sem':                    ensure => 'present', permanent => 'yes', value => '250 32000 100 128',}
  sysctl { 'net.ipv4.ip_local_port_range':  ensure => 'present', permanent => 'yes', value => '9000 65500',}
  sysctl { 'net.core.rmem_default':         ensure => 'present', permanent => 'yes', value => '262144',}
  sysctl { 'net.core.rmem_max':             ensure => 'present', permanent => 'yes', value => '4194304', }
  sysctl { 'net.core.wmem_default':         ensure => 'present', permanent => 'yes', value => '262144',}
  sysctl { 'net.core.wmem_max':             ensure => 'present', permanent => 'yes', value => '1048576',}
}

class oradb_12c {
  require oradb_os

    oradb::installdb{ '12.1.0.1_Linux-x86-64':
      version                => '12.1.0.1',
      file                   => 'linuxamd64_12c_database',
      databaseType           => 'EE',
      oracleBase             => hiera('oracle_base_dir'),
      oracleHome             => hiera('oracle_home_dir'),
      userBaseDir            => '/home',
      createUser             => true,
      bashProfile            => false,
      user                   => hiera('oracle_os_user'),
      group                  => hiera('oracle_os_group'),
      group_install          => 'oinstall',
      group_oper             => 'oper',
      downloadDir            => hiera('oracle_download_dir'),
      remoteFile             => false,
      puppetDownloadMntPoint => hiera('oracle_source'),
    }

    oradb::net{ 'config net8':
      oracleHome   => hiera('oracle_home_dir'),
      version      => '12.1',
      user         => hiera('oracle_os_user'),
      group        => hiera('oracle_os_group'),
      downloadDir  => hiera('oracle_download_dir'),
      require      => Oradb::Installdb['12.1.0.1_Linux-x86-64'],
    }

    oradb::listener{'start listener':
      oracleBase   => hiera('oracle_base_dir'),
      oracleHome   => hiera('oracle_home_dir'),
      user         => hiera('oracle_os_user'),
      group        => hiera('oracle_os_group'),
      action       => 'start',
      require      => Oradb::Net['config net8'],
    }

    oradb::database{ 'oraDb':
      oracleBase              => hiera('oracle_base_dir'),
      oracleHome              => hiera('oracle_home_dir'),
      version                 => '12.1',
      user                    => hiera('oracle_os_user'),
      group                   => hiera('oracle_os_group'),
      downloadDir             => hiera('oracle_download_dir'),
      action                  => 'create',
      dbName                  => hiera('oracle_database_name'),
      dbDomain                => hiera('oracle_database_domain_name'),
      sysPassword             => hiera('oracle_database_sys_password'),
      systemPassword          => hiera('oracle_database_system_password'),
      dataFileDestination     => "/oracle/oradata",
      recoveryAreaDestination => "/oracle/flash_recovery_area",
      characterSet            => "AL32UTF8",
      nationalCharacterSet    => "UTF8",
      emConfiguration         => 'NONE',
      memoryTotal             => '2500',
      sampleSchema            => 'FALSE',
      databaseType            => "MULTIPURPOSE",
      require                 => Oradb::Listener['start listener'],
    }

    oradb::dbactions{ 'start oraDb':
      oracleHome              => hiera('oracle_home_dir'),
      user                    => hiera('oracle_os_user'),
      group                   => hiera('oracle_os_group'),
      action                  => 'start',
      dbName                  => hiera('oracle_database_name'),
      require                 => Oradb::Database['oraDb'],
    }

    oradb::autostartdatabase{ 'autostart oracle':
      oracleHome              => hiera('oracle_home_dir'),
      user                    => hiera('oracle_os_user'),
      dbName                  => hiera('oracle_database_name'),
      require                 => Oradb::Dbactions['start oraDb'],
    }

}

class oradb_init {
  require oradb_12c

  ora_init_param{ 'SPFILE/OPEN_CURSORS@emrepos':
    ensure => 'present',
    value  => '600',
  }

  ora_init_param{ 'SPFILE/processes@emrepos':
    ensure => 'present',
    value  => '1000',
  }

  ora_init_param{'SPFILE/job_queue_processes@emrepos':
    ensure  => present,
    value   => '20',
  }

  ora_init_param{'SPFILE/session_cached_cursors@emrepos':
    ensure  => present,
    value   => '200',
  }

  ora_init_param{'SPFILE/db_securefile@emrepos':
    ensure  => present,
    value   => 'PERMITTED',
  }

  ora_init_param{'SPFILE/memory_target@emrepos':
    ensure  => present,
    value   => '3000M',
  }

  ora_init_param { 'SPFILE/PGA_AGGREGATE_TARGET@emrepos':
    ensure  => 'present',
    value   => '1G',
    require => Ora_init_param['SPFILE/memory_target@emrepos'],
  }

  ora_init_param { 'SPFILE/SGA_TARGET@emrepos':
    ensure  => 'present',
    value   => '1200M',
    require => Ora_init_param['SPFILE/memory_target@emrepos'],
  }
  ora_init_param { 'SPFILE/SHARED_POOL_SIZE@emrepos':
    ensure  => 'present',
    value   => '600M',
    require => Ora_init_param['SPFILE/memory_target@emrepos'],
  }

  db_control{'emrepos restart':
    ensure                  => 'running', #running|start|abort|stop
    instance_name           => hiera('oracle_database_name'),
    oracle_product_home_dir => hiera('oracle_home_dir'),
    os_user                 => hiera('oracle_os_user'),
    refreshonly             => true,
    subscribe               => [Ora_init_param['SPFILE/OPEN_CURSORS@emrepos'],
                                Ora_init_param['SPFILE/processes@emrepos'],
                                Ora_init_param['SPFILE/job_queue_processes@emrepos'],
                                Ora_init_param['SPFILE/session_cached_cursors@emrepos'],
                                Ora_init_param['SPFILE/db_securefile@emrepos'],
                                Ora_init_param['SPFILE/SGA_TARGET@emrepos'],
                                Ora_init_param['SPFILE/SHARED_POOL_SIZE@emrepos'],
                                Ora_init_param['SPFILE/PGA_AGGREGATE_TARGET@emrepos'],
                                Ora_init_param['SPFILE/memory_target@emrepos'],],
  }

}

class oradb_em_agent {

  # oradb::installem_agent{ 'em12104_agent':
  #   version                     => '12.1.0.4',
  #   source                      => 'https://10.10.10.25:7802/em/install/getAgentImage',
  #   install_type                => 'agentPull',
  #   install_platform            => 'Linux x86-64',
  #   oracle_base_dir             => '/oracle',
  #   agent_base_dir              => '/oracle/product/12.1/agent',
  #   agent_instance_home_dir     => '/oracle/product/12.1/agent/agent_inst',
  #   sysman_user                 => 'sysman',
  #   sysman_password             => 'Welcome01',
  #   agent_registration_password => 'Welcome01',
  #   agent_port                  => 1830,
  #   oms_host                    => '10.10.10.25',
  #   oms_port                    => 7802,
  #   em_upload_port              => 4903,
  #   user                        => 'oracle',
  #   group                       => 'dba',
  #   download_dir                => '/var/tmp/install',
  #   log_output                  => true,
  # }

  # oradb::installem_agent{ 'em12104_agent2':
  #   version                     => '12.1.0.4',
  #   source                      => '/var/tmp/install/agent.zip',
  #   install_type                => 'agentDeploy',
  #   oracle_base_dir             => '/oracle',
  #   agent_base_dir              => '/oracle/product/12.1/agent2',
  #   agent_instance_home_dir     => '/oracle/product/12.1/agent2/agent_inst',
  #   agent_registration_password => 'Welcome01',
  #   agent_port                  => 1832,
  #   oms_host                    => '10.10.10.25',
  #   em_upload_port              => 4903,
  #   user                        => 'oracle',
  #   group                       => 'dba',
  #   download_dir                => '/var/tmp/install',
  #   log_output                  => true,
  # }

}