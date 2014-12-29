# == Define: oradb::opatchupgrade
#
# upgrades oracle opatch
#
define oradb::opatchupgrade(
  $oracleHome              = undef,
  $patchFile               = undef,
  $csiNumber               = undef,
  $supportId               = undef,
  $opversion               = undef,
  $user                    = hiera('oradb:user'),
  $group                   = hiera('oradb:group'),
  $downloadDir             = hiera('oradb:download_dir'),
  $puppetDownloadMntPoint  = undef,
){
  $execPath = hiera('oradb:exec_path')
  $patchDir      = "${oracleHome}/OPatch"

  $supported_db_kernels = join( hiera('oradb:kernels'), '|')
  if ( $::kernel in $supported_db_kernels == false){
    fail("Unrecognized operating system, please use it on a ${supported_db_kernels} host")
  }

  # if a mount was not specified then get the install media from the puppet master
  if $puppetDownloadMntPoint == undef {
    $mountDir = hiera('oradb:module_mountpoint')
  } else {
    $mountDir = $puppetDownloadMntPoint
  }

  # check the opatch version
  $installedVersion  = opatch_version($oracleHome)

  if $installedVersion == $opversion {
    $continue = false
  } else {
    notify {"oradb::opatchupgrade ${title} ${installedVersion} installed - performing upgrade":}
    $continue = true
  }

  if ( $continue ) {

    if ! defined(File["${downloadDir}/${patchFile}"]) {
      file {"${downloadDir}/${patchFile}":
        ensure  => present,
        path    => "${downloadDir}/${patchFile}",
        source  => "${mountDir}/${patchFile}",
        mode    => '0775',
        owner   => $user,
        group   => $group,
        require => File[$downloadDir],
      }
    }

    file { $patchDir:
      ensure  => absent,
      recurse => true,
      force   => true,
    } ->
    exec { "extract opatch ${title} ${patchFile}":
      command   => "unzip -o ${downloadDir}/${patchFile} -d ${oracleHome}",
      require   => File["${downloadDir}/${patchFile}"],
      path      => $execPath,
      user      => $user,
      group     => $group,
      logoutput => false,
    }

    if ( $csiNumber != undef and supportId != undef ) {
      exec { "exec emocmrsp ${title} ${opversion}":
        cwd       => $patchDir,
        command   => "${patchDir}/ocm/bin/emocmrsp -repeater NONE ${csiNumber} ${supportId}",
        require   => Exec["extract opatch ${patchFile}"],
        path      => $execPath,
        user      => $user,
        group     => $group,
        logoutput => true,
      }
    } else {

      if ! defined(Package['expect']) {
        package { 'expect':
          ensure  => present,
        }
      }

      file { "${downloadDir}/opatch_upgrade_${title}_${opversion}.ksh":
        ensure  => present,
        content => template('oradb/ocm.rsp.erb'),
        mode    => '0775',
        owner   => $user,
        group   => $group,
        require => File[$downloadDir],
      }

      exec { "ksh ${downloadDir}/opatch_upgrade_${title}_${opversion}.ksh":
        cwd       => $patchDir,
        require   => [File["${downloadDir}/opatch_upgrade_${title}_${opversion}.ksh"],
                      Exec["extract opatch ${title} ${patchFile}"],
                      Package['expect'],],
        path      => $execPath,
        user      => $user,
        group     => $group,
        logoutput => true,
      }
    }
  }
}
