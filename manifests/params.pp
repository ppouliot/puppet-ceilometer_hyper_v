# Parameters for puppet-ceilometer
#
class ceilometer_hyper_v::params {

  case $::osfamily {
    #'RedHat': {
    #}
    #'Debian': {
    #}
    'windows':{
      $agent_compute_service_name   = 'ceilometer-agent-compute'
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: \
${::operatingsystem}, module ${module_name} only support osfamily \
windows")
    }
  }
}
