#    Copyright 2015 Mirantis, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.
#
class lma_collector::metrics::heka_monitoring (
  $dashboard_address = $lma_collector::params::dashboard_address,
  $dashboard_port    = $lma_collector::params::dashboard_port,
){
  include lma_collector::service

  heka::filter::sandbox { 'heka_monitoring':
    config_dir      => $lma_collector::params::config_dir,
    filename        => "${lma_collector::params::plugins_dir}/filters/heka_monitoring.lua",
    message_matcher => "Type == 'heka.all-report'",
    notify          => Class['lma_collector::service'],
  }

  # Dashboard is required to enable monitoring messages
  heka::output::dashboard { 'dashboard':
    config_dir        => $lma_collector::params::config_dir,
    dashboard_address => $dashboard_address,
    dashboard_port    => $dashboard_port,
    notify            => Class['lma_collector::service'],
  }
}
