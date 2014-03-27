# Class ceilometer_hyper_v
#
#  ceilometer base package & configuration
#
# == parameters
#  [*metering_secret*]
#    secret key for signing messages. Mandatory.
#  [*package_ensure*]
#    ensure state for package. Optional. Defaults to 'present'
#  [*debug*]
#    should the daemons log debug messages. Optional. Defaults to 'False'
#  [*log_dir*]
#    (optional) directory to which ceilometer logs are sent.
#    If set to boolean false, it will not log to any directory.
#    Defaults to '/var/log/ceilometer'
#  [*verbose*]
#    should the daemons log verbose messages. Optional. Defaults to 'False'
# [*rpc_backend*]
#    (optional) what rpc/queuing service to use
#    Defaults to impl_kombu (rabbitmq)
#  [*rabbit_host*]
#    ip or hostname of the rabbit server. Optional. Defaults to '127.0.0.1'
#  [*rabbit_port*]
#    port of the rabbit server. Optional. Defaults to 5672.
#  [*rabbit_hosts*]
#    array of host:port (used with HA queues). Optional. Defaults to undef.
#    If defined, will remove rabbit_host & rabbit_port parameters from config
#  [*rabbit_userid*]
#    user to connect to the rabbit server. Optional. Defaults to 'guest'
#  [*rabbit_password*]
#    password to connect to the rabbit_server. Optional. Defaults to empty.
#  [*rabbit_virtual_host*]
#    virtualhost to use. Optional. Defaults to '/'
#
# [*qpid_hostname*]
# [*qpid_port*]
# [*qpid_username*]
# [*qpid_password*]
# [*qpid_heartbeat*]
# [*qpid_protocol*]
# [*qpid_tcp_nodelay*]
# [*qpid_reconnect*]
# [*qpid_reconnect_timeout*]
# [*qpid_reconnect_limit*]
# [*qpid_reconnect_interval*]
# [*qpid_reconnect_interval_min*]
# [*qpid_reconnect_interval_max*]
# (optional) various QPID options
#

class ceilometer_hyper_v(
  $metering_secret             = false,
  $package_ensure              = 'present',
  $debug                       = false,
  $log_dir                     = 'C:/OpenStack/log',
  $verbose                     = false,
  $ceilometer_version          = '2013.2.2',
  $ceilometer_repository       = 'git+https://github.com/openstack/ceilometer',
  $rpc_backend                 = 'ceilometer.openstack.common.rpc.impl_kombu',
  $rabbit_host                 = '127.0.0.1',
  $rabbit_port                 = 5672,
  $rabbit_hosts                = undef,
  $rabbit_userid               = 'guest',
  $rabbit_password             = '',
  $rabbit_virtual_host         = '/',
  $qpid_hostname               = 'localhost',
  $qpid_port                   = 5672,
  $qpid_username               = 'guest',
  $qpid_password               = 'guest',
  $qpid_heartbeat              = 60,
  $qpid_protocol               = 'tcp',
  $qpid_tcp_nodelay            = true,
  $qpid_reconnect              = true,
  $qpid_reconnect_timeout      = 0,
  $qpid_reconnect_limit        = 0,
  $qpid_reconnect_interval_min = 0,
  $qpid_reconnect_interval_max = 0,
  $qpid_reconnect_interval     = 0
) {

  validate_string($metering_secret)


  include ceilometer_hyper_v::params

#  File {
#    require => Package['ceilometer-hyperv-common'],
#  }

  file { 'C:/OpenStack/etc/ceilometer/':
    ensure  => directory,
    mode    => '0750',
  }

  file { 'C:/OpenStack/etc/ceilometer/ceilometer.conf':
    mode    => '0640',
  }

  exec { 'install-ceilometer':
    command   => "pip install ${ceilometer_repository}@${ceilometer_version}",
    unless    => "\$output = pip freeze; exit !(\$output.ToLower().Contains(\"ceilometer==${ceilometer_version}\".ToLower()))",
    provider  => powershell,
  }

# luisfdez: Want to use this approach using meta python module 'ceilometer-common-hyperv'
#  package { 'ceilometer-common':
#    ensure   => $package_ensure,
#    source   => $::ceilometer_hyper_v::params::common_package_source,
#    provider => $::ceilometer_hyper_v::params::common_package_provider,
#    name     => $::ceilometer_hyper_v::params::common_package_name,
#  }

  Exec['install-ceilometer'] -> Hyperv_ceilometer_config<||>

  if $rpc_backend == 'ceilometer.openstack.common.rpc.impl_kombu' {

    if $rabbit_hosts {
      hyperv_ceilometer_config { 'DEFAULT/rabbit_host': ensure => absent }
      hyperv_ceilometer_config { 'DEFAULT/rabbit_port': ensure => absent }
      hyperv_ceilometer_config { 'DEFAULT/rabbit_hosts':
        value => join($rabbit_hosts, ',')
      }
      } else {
      hyperv_ceilometer_config { 'DEFAULT/rabbit_host': value => $rabbit_host }
      hyperv_ceilometer_config { 'DEFAULT/rabbit_port': value => $rabbit_port }
      hyperv_ceilometer_config { 'DEFAULT/rabbit_hosts':
        value => "${rabbit_host}:${rabbit_port}"
      }
    }

      if size($rabbit_hosts) > 1 {
        hyperv_ceilometer_config { 'DEFAULT/rabbit_ha_queues': value => true }
      } else {
        hyperv_ceilometer_config { 'DEFAULT/rabbit_ha_queues': value => false }
      }

      hyperv_ceilometer_config {
        'DEFAULT/rabbit_userid'          : value => $rabbit_userid;
        'DEFAULT/rabbit_password'        : value => $rabbit_password;
        'DEFAULT/rabbit_virtual_host'    : value => $rabbit_virtual_host;
      }
  }

  if $rpc_backend == 'ceilometer.openstack.common.rpc.impl_qpid' {

    hyperv_ceilometer_config {
      'DEFAULT/qpid_hostname'              : value => $qpid_hostname;
      'DEFAULT/qpid_port'                  : value => $qpid_port;
      'DEFAULT/qpid_username'              : value => $qpid_username;
      'DEFAULT/qpid_password'              : value => $qpid_password;
      'DEFAULT/qpid_heartbeat'             : value => $qpid_heartbeat;
      'DEFAULT/qpid_protocol'              : value => $qpid_protocol;
      'DEFAULT/qpid_tcp_nodelay'           : value => $qpid_tcp_nodelay;
      'DEFAULT/qpid_reconnect'             : value => $qpid_reconnect;
      'DEFAULT/qpid_reconnect_timeout'     : value => $qpid_reconnect_timeout;
      'DEFAULT/qpid_reconnect_limit'       : value => $qpid_reconnect_limit;
      'DEFAULT/qpid_reconnect_interval_min': value => $qpid_reconnect_interval_min;
      'DEFAULT/qpid_reconnect_interval_max': value => $qpid_reconnect_interval_max;
      'DEFAULT/qpid_reconnect_interval'    : value => $qpid_reconnect_interval;
    }

  }

  # Once we got here, we can act as an honey badger on the rpc used.
  hyperv_ceilometer_config {
    'DEFAULT/rpc_backend'            : value => $rpc_backend;
    'DEFAULT/metering_secret'        : value => $metering_secret;
    'DEFAULT/debug'                  : value => $debug;
    'DEFAULT/verbose'                : value => $verbose;
    'DEFAULT/notification_topics'    : value => 'notifications';
  }

  # Log configuration
  if $log_dir {
    hyperv_ceilometer_config {
      'DEFAULT/log_dir' : value  => $log_dir;
    }
  } else {
    hyperv_ceilometer_config {
      'DEFAULT/log_dir' : ensure => absent;
    }
  }
}
