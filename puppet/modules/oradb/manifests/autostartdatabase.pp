# == Define: orautils::nodemanagerautostart
#
#  autostart of the nodemanager for linux
#
define oradb::autostartdatabase(
  $oracleHome  = undef,
  $dbName      = undef,
  $user        = hiera('oradb:user'),
){
  include oradb::prepareautostart

  $execPath      = hiera('oradb:exec_path')
  $oraTab        = hiera('oradb:oratab')
  $dboraLocation = hiera('oradb:dbora_dir')

  case $::kernel {
    'Linux': {
      $sedCommand = "sed -i -e's/:N/:Y/g' ${oraTab}"
    }
    'SunOS': {
      $sedCommand = "sed -e's/:N/:Y/g' ${oraTab} > /tmp/oratab.tmp && mv /tmp/oratab.tmp ${oraTab}"
    }
    default: {
      fail('Unrecognized operating system, please use it on a Linux or SunOS host')
    }
  }

  exec { "set dbora ${dbName}:${oracleHome}":
    command   => $sedCommand,
    unless    => "/bin/grep '^${dbName}:${oracleHome}:Y' ${oraTab}",
    require   => File["${dboraLocation}/dbora"],
    path      => $execPath,
    logoutput => true,
  }

}

