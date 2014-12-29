# == Class: oradb::installdb
#
# The databaseType value should contain only one of these choices.
# EE     : Enterprise Edition
# SE     : Standard Edition
# SEONE  : Standard Edition One
#
#
define oradb::installdb(
  $version                 = undef,
  $file                    = undef,
  $databaseType            = 'SE',
  $oraInventoryDir         = undef,
  $oracleBase              = undef,
  $oracleHome              = undef,
  $eeOptionsSelection      = false,
  $eeOptionalComponents    = undef, # 'oracle.rdbms.partitioning:11.2.0.4.0,oracle.oraolap:11.2.0.4.0,oracle.rdbms.dm:11.2.0.4.0,oracle.rdbms.dv:11.2.0.4.0,oracle.rdbms.lbac:11.2.0.4.0,oracle.rdbms.rat:11.2.0.4.0'
  $createUser              = undef,
  $bashProfile             = true,
  $user                    = hiera('oradb:user'),
  $userBaseDir             = hiera('oradb:user_base_dir','NotFound'),
  $group                   = hiera('oradb:group'),
  $group_install           = hiera('oradb:group_install'),
  $group_oper              = hiera('oradb:group_oper'),
  $downloadDir             = hiera('oradb:download_dir'),
  $zipExtract              = true,
  $puppetDownloadMntPoint  = undef,
  $remoteFile              = true,
  $cluster_nodes           = undef,
)
{
  if ( $createUser == true ){
    fail("createUser parameter on installdb ${title} is removed from this oradb module, you need to create the oracle user and its groups yourself")
  }

  if ( $createUser == false ){
    notify {"createUser parameter on installdb ${title} can be removed, createUser feature is removed from this oradb module":}
  }

  $supported_db_versions = join( hiera('oradb:versions'), '|')
  if ( $version in $supported_db_versions == false ){
    fail("Unrecognized database install version, use ${supported_db_versions}")
  }

  $supported_db_kernels = join( hiera('oradb:kernels'), '|')
  if ( $::kernel in $supported_db_kernels == false){
    fail("Unrecognized operating system, please use it on a ${supported_db_kernels} host")
  }

  $supported_db_types = join( hiera('oradb:database_types'), '|')
  if ( $databaseType in $supported_db_types == false){
    fail("Unrecognized database type, please use ${supported_db_types}")
  }

  if ( $oracleBase == undef or is_string($oracleBase) == false) {fail('You must specify an oracleBase') }
  if ( $oracleHome == undef or is_string($oracleHome) == false) {fail('You must specify an oracleHome') }

  if ( $oracleBase in $oracleHome == false ){
    fail('oracleHome folder should be under the oracleBase folder')
  }

  # check if the oracle software already exists
  $found = oracle_exists( $oracleHome )

  if $found == undef {
    $continue = true
  } else {
    if ( $found ) {
      $continue = false
    } else {
      notify {"oradb::installdb ${oracleHome} does not exists":}
      $continue = true
    }
  }

  $execPath = hiera('oradb:exec_path')

  if $puppetDownloadMntPoint == undef {
    $mountPoint = hiera('oradb:module_mountpoint')
  } else {
    $mountPoint = $puppetDownloadMntPoint
  }

  if $oraInventoryDir == undef {
    $oraInventory = "${oracleBase}/oraInventory"
  } else {
    $oraInventory = "${oraInventoryDir}/oraInventory"
  }

  oradb::utils::dbstructure{"oracle structure ${version}":
    oracle_base_home_dir => $oracleBase,
    ora_inventory_dir    => $oraInventory,
    os_user              => $user,
    os_group_install     => $group_install,
    download_dir         => $downloadDir,
  }

  if ( $continue ) {

    if ( $zipExtract ) {
      # In $downloadDir, will Puppet extract the ZIP files or
      # is this a pre-extracted directory structure.

      if ( $version in hiera('oradb:versions_full')) {
        $file1 =  "${file}_1of2.zip"
        $file2 =  "${file}_2of2.zip"
      }

      if ( $version in hiera('oradb:versions_patch')) {
        $file1 =  "${file}_1of7.zip"
        $file2 =  "${file}_2of7.zip"
      }

      if $remoteFile == true {

        file { "${downloadDir}/${file1}":
          ensure  => present,
          source  => "${mountPoint}/${file1}",
          mode    => '0775',
          owner   => $user,
          group   => $group,
          require => Oradb::Utils::Dbstructure["oracle structure ${version}"],
          before  => Exec["extract ${downloadDir}/${file1}"],
        }
        # db file 2 installer zip
        file { "${downloadDir}/${file2}":
          ensure  => present,
          source  => "${mountPoint}/${file2}",
          mode    => '0775',
          owner   => $user,
          group   => $group,
          require => File["${downloadDir}/${file1}"],
          before  => Exec["extract ${downloadDir}/${file2}"]
        }
        $source = $downloadDir
      } else {
        $source = $mountPoint
      }

      exec { "extract ${downloadDir}/${file1}":
        command   => "unzip -o ${source}/${file1} -d ${downloadDir}/${file}",
        timeout   => 0,
        logoutput => false,
        path      => $execPath,
        user      => $user,
        group     => $group,
        require   => Oradb::Utils::Dbstructure["oracle structure ${version}"],
        before    => Exec["install oracle database ${title}"],
      }
      exec { "extract ${downloadDir}/${file2}":
        command   => "unzip -o ${source}/${file2} -d ${downloadDir}/${file}",
        timeout   => 0,
        logoutput => false,
        path      => $execPath,
        user      => $user,
        group     => $group,
        require   => Exec["extract ${downloadDir}/${file1}"],
        before    => Exec["install oracle database ${title}"],
      }
    }

    oradb::utils::dborainst{"database orainst ${version}":
      ora_inventory_dir => $oraInventory,
      os_group          => $group_install,
    }

    if ! defined(File["${downloadDir}/db_install_${version}.rsp"]) {
      file { "${downloadDir}/db_install_${version}.rsp":
        ensure  => present,
        content => template("oradb/db_install_${version}.rsp.erb"),
        mode    => '0775',
        owner   => $user,
        group   => $group,
        require => Oradb::Utils::Dborainst["database orainst ${version}"],
      }
    }

    exec { "install oracle database ${title}":
      command     => "/bin/sh -c 'unset DISPLAY;${downloadDir}/${file}/database/runInstaller -silent -waitforcompletion -ignoreSysPrereqs -ignorePrereq -responseFile ${downloadDir}/db_install_${version}.rsp'",
      creates     => "${oracleHome}/dbs",
      environment => ["USER=${user}","LOGNAME=${user}"],
      timeout     => 0,
      returns     => [6,0],
      path        => $execPath,
      user        => $user,
      group       => $group_install,
      cwd         => $oracleBase,
      logoutput   => true,
      require     => [Oradb::Utils::Dborainst["database orainst ${version}"],
                      File["${downloadDir}/db_install_${version}.rsp"]],
    }

    if ( $bashProfile == true ) {
      if ! defined(File["${userBaseDir}/${user}/.bash_profile"]) {
        file { "${userBaseDir}/${user}/.bash_profile":
          ensure  => present,
          # content => template('oradb/bash_profile.erb'),
          content => regsubst(template('oradb/bash_profile.erb'), '\r\n', "\n", 'EMG'),
          mode    => '0775',
          owner   => $user,
          group   => $group,
          require => Oradb::Utils::Dbstructure["oracle structure ${version}"],
        }
      }
    }

    exec { "run root.sh script ${title}":
      command   => "${oracleHome}/root.sh",
      user      => 'root',
      group     => 'root',
      path      => $execPath,
      cwd       => $oracleBase,
      logoutput => true,
      require   => Exec["install oracle database ${title}"],
    }

    file { $oracleHome:
      ensure  => directory,
      recurse => false,
      replace => false,
      mode    => '0775',
      owner   => $user,
      group   => $group_install,
      require => Exec["install oracle database ${title}","run root.sh script ${title}"],
    }

    # cleanup
    if ( $zipExtract ) {
      exec { "remove oracle db extract folder ${title}":
        command => "rm -rf ${downloadDir}/${file}",
        user    => 'root',
        group   => 'root',
        path    => $execPath,
        cwd     => $oracleBase,
        require => [Exec["install oracle database ${title}"],
                    Exec["run root.sh script ${title}"],],
      }

      if ( $remoteFile == true ){
        exec { "remove oracle db file1 ${file1} ${title}":
          command => "rm -rf ${downloadDir}/${file1}",
          user    => 'root',
          group   => 'root',
          path    => $execPath,
          cwd     => $oracleBase,
          require => [Exec["install oracle database ${title}"],
                      Exec["run root.sh script ${title}"],],
        }
        exec { "remove oracle db file2 ${file2} ${title}":
          command => "rm -rf ${downloadDir}/${file2}",
          user    => 'root',
          group   => 'root',
          path    => $execPath,
          cwd     => $oracleBase,
          require => [Exec["install oracle database ${title}"],
                      Exec["run root.sh script ${title}"],],
        }
      }
    }
  }
}
