# == Class: oradb::dbactions
#
#
# action        =  stop|start
#
#
define oradb::dbactions(
  $oracleHome  = undef,
  $user        = hiera('oradb:user'),
  $group       = hiera('oradb:group'),
  $action      = 'start',
  $dbName      = 'orcl',
){
  db_control{"instance control ${title}":
    ensure                  => $action,   #running|start|abort|stop
    instance_name           => $dbName,
    oracle_product_home_dir => $oracleHome,
    os_user                 => $user,
  }
}