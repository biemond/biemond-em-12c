# == Class: oradb::net
#
define oradb::net(
  $oracleHome   = undef,
  $version      = undef,
  $user         = hiera('oradb:user'),
  $group        = hiera('oradb:group'),
  $downloadDir  = hiera('oradb:download_dir'),
  $dbPort       = '1521',
){
  if ( $version in hiera('oradb:net_versions') == false ) {
    fail('Unrecognized version for oradb::net')
  }

  $execPath = hiera('oradb:exec_path')

  file { "${downloadDir}/netca_${version}.rsp":
    ensure  => present,
    content => template("oradb/netca_${version}.rsp.erb"),
    mode    => '0775',
    owner   => $user,
    group   => $group,
    require => File[$downloadDir],
  }

  exec { "install oracle net ${title}":
    command     => "${oracleHome}/bin/netca /silent /responsefile ${downloadDir}/netca_${version}.rsp",
    require     => File["${downloadDir}/netca_${version}.rsp"],
    creates     => "${oracleHome}/network/admin/listener.ora",
    path        => $execPath,
    user        => $user,
    group       => $group,
    environment => ["USER=${user}",],
    logoutput   => true,
  }
}
