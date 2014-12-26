# == define: oradb::utils::dbstructure
#
#  create directories for the download folder and oracle base home
#
#
##
define oradb::utils::dbstructure(
  $oracle_base_home_dir = undef,
  $ora_inventory_dir    = undef,
  $os_user              = undef,
  $os_group_install     = undef,
  $download_dir         = undef,
  $log_output           = false,
)
{
  $exec_path = '/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:'

  # create all folders
  if !defined(Exec["create ${oracle_base_home_dir} directory"]) {
    exec { "create ${oracle_base_home_dir} directory":
      command   => "mkdir -p ${oracle_base_home_dir}",
      unless    => "test -d ${oracle_base_home_dir}",
      user      => 'root',
      path      => $exec_path,
      logoutput => $log_output,
    }
  }

  if !defined(Exec["create ${download_dir} home directory"]) {
    exec { "create ${download_dir} home directory":
      command   => "mkdir -p ${download_dir}",
      unless    => "test -d ${download_dir}",
      user      => 'root',
      path      => $exec_path,
      logoutput => $log_output,
    }
  }

  # also set permissions on downloadDir
  if !defined(File[$download_dir]) {
    # check oracle install folder
    file { $download_dir:
      ensure  => directory,
      recurse => false,
      replace => false,
      mode    => '0775',
      owner   => $os_user,
      group   => $os_group_install,
      require => [Exec["create ${download_dir} home directory"],],
    }
  }

  # also set permissions on oracleHome
  if !defined(File[$oracle_base_home_dir]) {
    file { $oracle_base_home_dir:
      ensure  => directory,
      recurse => false,
      replace => false,
      mode    => '0775',
      owner   => $os_user,
      group   => $os_group_install,
      require => Exec["create ${oracle_base_home_dir} directory"],
    }
  }

  # also set permissions on oraInventory
  if !defined(File[$ora_inventory_dir]) {
    file { $ora_inventory_dir:
      ensure  => directory,
      recurse => false,
      replace => false,
      mode    => '0775',
      owner   => $os_user,
      group   => $os_group_install,
      require => [Exec["create ${oracle_base_home_dir} directory"],
                  File[$oracle_base_home_dir],],
    }
  }
}