# == Define: oradb::opatch
#
# installs oracle patches for Oracle products
#
#
define oradb::opatch(
  $ensure                  = 'present',  #present|absent
  $oracleProductHome       = undef,
  $patchId                 = undef,
  $patchFile               = undef,
  $clusterWare             = false, # opatch auto or opatch apply
  $bundleSubPatchId        = undef,
  $bundleSubFolder         = undef,
  $user                    = hiera('oradb:user'),
  $group                   = hiera('oradb:group'),
  $downloadDir             = hiera('oradb:download_dir'),
  $ocmrf                   = false,
  $puppetDownloadMntPoint  = undef,
  $remoteFile              = true,
)
{
  $supported_db_kernels = join( hiera('oradb:kernels'), '|')
  if ( $::kernel in $supported_db_kernels == false){
    fail("Unrecognized operating system, please use it on a ${supported_db_kernels} host")
  }

  $execPath    = hiera('oradb:exec_path')
  $oraInstPath = hiera('oradb:orainst_dir')

  if $puppetDownloadMntPoint == undef {
    $mountPoint =  hiera('oradb:module_mountpoint')
  } else {
    $mountPoint =  $puppetDownloadMntPoint
  }

  if $ensure == 'present' {
    if $remoteFile == true {
      # the patch used by the opatch
      if ! defined(File["${downloadDir}/${patchFile}"]) {
        file { "${downloadDir}/${patchFile}":
          ensure  => present,
          source  => "${mountPoint}/${patchFile}",
          mode    => '0775',
          owner   => $user,
          group   => $group,
          require => File[$downloadDir],
        }
      }
    }
  }

  if $ensure == 'present' {
    if $remoteFile == true {
      exec { "extract opatch ${patchFile} ${title}":
        command   => "unzip -n ${downloadDir}/${patchFile} -d ${downloadDir}",
        require   => File["${downloadDir}/${patchFile}"],
        creates   => "${downloadDir}/${patchId}",
        path      => $execPath,
        user      => $user,
        group     => $group,
        logoutput => false,
        before    => Db_opatch["${patchId} ${title}"],
      }
    } else {
      exec { "extract opatch ${patchFile} ${title}":
        command   => "unzip -n ${mountPoint}/${patchFile} -d ${downloadDir}",
        creates   => "${downloadDir}/${patchId}",
        path      => $execPath,
        user      => $user,
        group     => $group,
        logoutput => false,
        before    => Db_opatch["${patchId} ${title}"],
      }
    }
  }

  # sometimes the bundle patch inside an other folder
  if ( $bundleSubFolder ) {
    $extracted_patch_dir = "${downloadDir}/${patchId}/${bundleSubFolder}"
  } else {
    $extracted_patch_dir = "${downloadDir}/${patchId}"
  }

  if $ocmrf == true {

    db_opatch{ "${patchId} ${title}":
      ensure                  => $ensure,
      patch_id                => $patchId,
      os_user                 => $user,
      oracle_product_home_dir => $oracleProductHome,
      orainst_dir             => $oraInstPath,
      extracted_patch_dir     => $extracted_patch_dir,
      ocmrf_file              => "${oracleProductHome}/OPatch/ocm.rsp",
      bundle_sub_patch_id     => $bundleSubPatchId,
      opatch_auto             => $clusterWare,
    }

  } else {

    db_opatch{ "${patchId} ${title}":
      ensure                  => $ensure,
      patch_id                => $patchId,
      os_user                 => $user,
      oracle_product_home_dir => $oracleProductHome,
      orainst_dir             => $oraInstPath,
      extracted_patch_dir     => $extracted_patch_dir,
      bundle_sub_patch_id     => $bundleSubPatchId,
      opatch_auto             => $clusterWare,
    }

  }
}