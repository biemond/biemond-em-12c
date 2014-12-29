# == Class: oradb::database
#
#
# action        =  createDatabase|deleteDatabase
# databaseType  = MULTIPURPOSE|DATA_WAREHOUSING|OLTP
#
define oradb::database(
  $oracleBase               = undef,
  $oracleHome               = undef,
  $version                  = undef, # 11.2|12.1
  $user                     = hiera('oradb:user'),
  $group                    = hiera('oradb:group'),
  $downloadDir              = hiera('oradb:download_dir'),
  $action                   = 'create',
  $template                 = undef,
  $dbName                   = 'orcl',
  $dbDomain                 = undef,
  $dbPort                   = '1521',
  $sysPassword              = 'Welcome01',
  $systemPassword           = 'Welcome01',
  $dataFileDestination      = undef,
  $recoveryAreaDestination  = undef,
  $characterSet             = 'AL32UTF8',
  $nationalCharacterSet     = 'UTF8',
  $initParams               = undef,
  $sampleSchema             = TRUE,
  $memoryPercentage         = '40',
  $memoryTotal              = '800',
  $databaseType             = 'MULTIPURPOSE', # MULTIPURPOSE|DATA_WAREHOUSING|OLTP
  $emConfiguration          = 'NONE',  # CENTRAL|LOCAL|ALL|NONE
  $storageType              = 'FS', #FS|CFS|ASM
  $asmSnmpPassword          = 'Welcome01',
  $dbSnmpPassword           = 'Welcome01',
  $asmDiskgroup             = 'DATA',
  $recoveryDiskgroup        = undef,
  $cluster_nodes            = undef,
  $containerDatabase        = false, # 12.1 feature for pluggable database
){
  if ( $version in hiera('oradb:database_versions') == false ) {
    fail('Unrecognized version for oradb::database')
  }

  $supported_db_kernels = join( hiera('oradb:kernels'), '|')
  if ( $::kernel in $supported_db_kernels == false){
    fail("Unrecognized operating system, please use it on a ${supported_db_kernels} host")
  }

  if $action == 'create' {
    $operationType = 'createDatabase'
  } elsif $action == 'delete' {
    $operationType = 'deleteDatabase'
  } else {
    fail('Unrecognized database action')
  }

  if ( $databaseType in hiera('oradb:instance_types') == false ) {
    fail('Unrecognized databaseType')
  }

  if ( $emConfiguration in hiera('oradb:instance_em_configuration') == false) {
    fail('Unrecognized emConfiguration')
  }

  if ( $storageType in hiera('oradb:instance_storage_type') == false ) {
    fail('Unrecognized storageType')
  }

  if ( $version == '11.2' and $containerDatabase == true ){
    fail('container or pluggable database is not supported on version 11.2')
  }

  $execPath = hiera('oradb:exec_path')
  $userBase = hiera('oradb:user_base_dir','NotFound')
  $userHome = "${userBase}/${user}"

  if (is_hash($initParams) or is_string($initParams)) {
    if is_hash($initParams) {
      $initParamsArray = sort(join_keys_to_values($initParams, '='))
      $sanitizedInitParams = join($initParamsArray,',')
    } else {
      $sanitizedInitParams = $initParams
    }
  } else {
    fail 'initParams only supports a String or a Hash as value type'
  }

  $sanitized_title = regsubst($title, '[^a-zA-Z0-9.-]', '_', 'G')

  if $dbDomain {
    $globalDbName = "${dbName}.${dbDomain}"
  } else {
    $globalDbName = $dbName
  }

  if ! defined(File["${downloadDir}/database_${sanitized_title}.rsp"]) {
    file { "${downloadDir}/database_${sanitized_title}.rsp":
      ensure  => present,
      content => template("oradb/dbca_${version}.rsp.erb"),
      mode    => '0775',
      owner   => $user,
      group   => $group,
      before  => Exec["oracle database ${title}"],
      require => File[$downloadDir],
    }
  }

  if ( $template ) {
    $templatename = "${downloadDir}/${template}_${sanitized_title}.dbt"
    file { $templatename:
      ensure  => present,
      content => template("oradb/${template}.dbt.erb"),
      mode    => '0775',
      owner   => $user,
      group   => $group,
      before  => Exec["oracle database ${title}"],
      require => File[$downloadDir],
    }
  }

  if $action == 'create' {
    if ( $template ) {
      $command = "${oracleHome}/bin/dbca -silent -createDatabase -templateName ${templatename} -gdbname ${globalDbName} -responseFile NO_VALUE -sysPassword ${sysPassword} -systemPassword ${systemPassword} -dbsnmpPassword ${dbSnmpPassword} -asmsnmpPassword ${asmSnmpPassword} -storageType ${storageType} -emConfiguration ${emConfiguration}"
    } else {
      $command = "${oracleHome}/bin/dbca -silent -responseFile ${downloadDir}/database_${sanitized_title}.rsp"
    }
    exec { "oracle database ${title}":
      command     => $command,
      creates     => "${oracleBase}/admin/${dbName}",
      timeout     => 0,
      path        => $execPath,
      user        => $user,
      group       => $group,
      cwd         => $userHome,
      environment => ["USER=${user}",],
      logoutput   => true,
    }
  } elsif $action == 'delete' {
    exec { "oracle database ${title}":
      command     => "${oracleHome}/bin/dbca -silent -responseFile ${downloadDir}/database_${sanitized_title}.rsp",
      onlyif      => "ls ${oracleBase}/admin/${dbName}",
      timeout     => 0,
      path        => $execPath,
      user        => $user,
      group       => $group,
      cwd         => $userHome,
      environment => ["USER=${user}",],
      logoutput   => true,
    }
  }

}