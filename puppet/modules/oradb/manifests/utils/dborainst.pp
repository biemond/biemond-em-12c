# == define: oradb::utils::dborainst
#
#  creates oraInst.loc for oracle products
#
#
##
define oradb::utils::dborainst(
  $ora_inventory_dir = undef,
  $os_group          = undef,
){

  $oraInstPath = hiera('oradb:orainst_dir')
  if ( $::kernel == 'SunOS'){
    # just to be sure , create the base dir
    if !defined(File[$oraInstPath]) {
      file { $oraInstPath:
        ensure => directory,
        before => File["${oraInstPath}/oraInst.loc"],
        mode   => '0755',
      }
    }
  }

  if !defined(File["${oraInstPath}/oraInst.loc"]) {
    file { "${oraInstPath}/oraInst.loc":
      ensure  => present,
      content => template('oradb/oraInst.loc.erb'),
      mode    => '0755',
    }
  }
}
