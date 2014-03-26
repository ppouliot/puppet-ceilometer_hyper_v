# The ceilometer_hyper_v::agent::compute class installs the ceilometer compute agent
# Include this class on all nova compute nodes
#
# == Parameters
#  [*enabled*]
#    should the service be started or not
#    Optional. Defaults to true
#
class ceilometer_hyper_v::agent::compute (
  $enabled = true,
) inherits ceilometer_hyper_v {

  include ceilometer_hyper_v::params

  Hyperv_ceilometer_config<||> ~> Service['ceilometer-agent-compute']

  Exec['install-ceilometer'] -> Service['ceilometer-agent-compute']

  #package { 'ceilometer-agent-compute':
  #  ensure => installed,
  #  name   => $::ceilometer_hyper_v::params::agent_compute_package_name,
  #}

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  file { "C:/OpenStack/etc/ceilometer/pipeline.yaml":
    ensure             => file,
    source_permissions => ignore,
    source             => "puppet:///modules/ceilometer_hyper_v/pipeline.yaml",
  }

  file { "C:/OpenStack/Services/CeilometerAgentComputeService.py":
    ensure             => file,
    source_permissions => ignore,
    source             => "puppet:///modules/ceilometer_hyper_v/CeilometerAgentComputeService.py",
  }

  windows_python::windows_service { $::ceilometer_hyper_v::params::agent_compute_service_name:
    description => "${::ceilometer_hyper_v::params::agent_compute_service_name} service for Hyper-V",
    arguments   => '--config-file=C:\OpenStack\etc\ceilometer\ceilometer.conf',
    script      => "C:\\OpenStack\\services\\CeilometerAgentComputeService.CeilometerAgentComputeService",
    require     => File["C:/OpenStack/Services/CeilometerAgentComputeService.py"],
    before      => Service[$::ceilometer_hyper_v::params::agent_compute_service_name],
  }

  Exec['install-ceilometer'] -> Service['ceilometer-agent-compute']
  service { 'ceilometer-agent-compute':
    ensure     => $service_ensure,
    name       => $::ceilometer_hyper_v::params::agent_compute_service_name,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
  }

  hyperv_ceilometer_config {
    'DEFAULT/hypervisor_inspector'        : value => 'hyperv';
    'DEFAULT/pipeline_cfg_file'           : value => 'C:/OpenStack/etc/ceilometer/pipeline.yaml';
  }

  hyperv_nova_config {
    'DEFAULT/instance_usage_audit'        : value => 'True';
    'DEFAULT/instance_usage_audit_period' : value => 'hour';
    'HYPERV/enable_instance_metrics_collection': value => true;
  }

  #NOTE(dprince): This is using a custom (inline) file_line provider
  # until this lands upstream:
  # https://github.com/puppetlabs/puppetlabs-stdlib/pull/174
  Hyperv_nova_config<| |> {
    before +> File_line_after[
      'nova-notification-driver-common',
      'nova-notification-driver-ceilometer'
    ],
  }

  file_line_after {
    'nova-notification-driver-common':
      line   =>
        'notification_driver=nova.openstack.common.notifier.rpc_notifier',
      path   => 'C:/OpenStack/etc/nova/nova.conf',
      after  => '^\s*\[DEFAULT\]',
      notify => Service['nova-compute'];
    'nova-notification-driver-ceilometer':
      line   => 'notification_driver=ceilometer.compute.nova_notifier',
      path   => 'C:/OpenStack/etc/nova/nova.conf',
      after  => '^\s*\[DEFAULT\]',
      notify => Service['nova-compute'];
  }

}
