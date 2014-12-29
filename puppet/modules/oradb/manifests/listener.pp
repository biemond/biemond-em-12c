# == Class: oradb::listener
#
#
#    oradb::listener{'start listener':
#            oracleBase   => '/oracle',
#            oracleHome   => '/oracle/product/11.2/db',
#            user         => 'oracle',
#            group        => 'dba',
#            action       => 'start',
#         }
#
#
#
define oradb::listener( $oracleBase  = undef,
                        $oracleHome  = undef,
                        $user        = hiera('oradb:user'),
                        $group       = hiera('oradb:group'),
                        $action      = 'start',
)
{
  $execPath = hiera('oradb:exec_path')


  case $::kernel {
    'Linux': {
      $ps_bin = hiera('oradb:ps_bin')
      $ps_arg = hiera('oradb:ps_arg')
    }
    'SunOS': {
      $ps_arg = hiera('oradb:ps_arg')
      if $::kernelrelease == '5.11' {
        $ps_bin =  hiera('oradb:ps_bin_5_11')
      } else {
        $ps_bin = hiera('oradb:ps_bin')
      }
    }
    default: {
      fail('Unrecognized operating system')
    }
  }

  $command  = "${ps_bin} ${ps_arg} | /bin/grep -v grep | /bin/grep '${$oracleHome}/bin/tnslsnr'"

  if $action == 'start' {
    exec { "listener start ${title}":
      command     => "${oracleHome}/bin/lsnrctl ${action}",
      path        => $execPath,
      user        => $user,
      group       => $group,
      environment => ["ORACLE_HOME=${oracleHome}", "ORACLE_BASE=${oracleBase}", "LD_LIBRARY_PATH=${oracleHome}/lib"],
      logoutput   => true,
      unless      => $command,
    }
  } else {
    exec { "listener other ${title}":
      command     => "${oracleHome}/bin/lsnrctl ${action}",
      path        => $execPath,
      user        => $user,
      group       => $group,
      environment => ["ORACLE_HOME=${oracleHome}", "ORACLE_BASE=${oracleBase}", "LD_LIBRARY_PATH=${oracleHome}/lib"],
      logoutput   => true,
      onlyif      => $command,
    }
  }
}