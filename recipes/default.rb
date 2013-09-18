#
# Cookbook Name:: fluentd
# Recipe:: default
#
# Copyright 2011, Treasure Data, Inc.
#

group 'td-agent' do
  group_name 'td-agent'
  gid        403
  action     [:create]
end

user 'td-agent' do
  comment  'td-agent'
  uid      403
  group    'td-agent'
  home     '/var/run/td-agent'
  shell    '/bin/false'
  password nil
  supports :manage_home => true
  action   [:create, :manage]
end

directory '/etc/td-agent/' do
  owner  'td-agent'
  group  'td-agent'
  mode   '0755'
  action :create
end

directory '/var/log/td-agent/tmp' do
  owner  'td-agent'
  group  'td-agent'
  mode   '0755'
  recursive 'true'
  action :create
end

package "libssl0.9.8" do
  action :install
end

case node['platform']
when "ubuntu"
  dist = node['lsb']['codename']
  if dist == 'raring' 
    remote_file "#{Chef::Config[:file_cache_path]}/td-agent_#{node['td_agent']['version']}_amd64.deb"  do
      source "http://packages.treasure-data.com/debian/pool/contrib/t/td-agent/td-agent_#{node['td_agent']['version']}_amd64.deb"
    end
    dpkg_package "#{Chef::Config[:file_cache_path]}/td-agent_#{node['td_agent']['version']}_amd64.deb" do
      action :install
    end
  else
    source = (dist == 'precise') ? "http://packages.treasure-data.com/precise/" : "http://packages.treasure-data.com/debian/"
    apt_repository "treasure-data" do
      uri source
      distribution dist
      components ["contrib"]
      action :add
    end
  end
when "centos", "redhat"
  yum_repository "treasure-data" do
    url "http://packages.treasure-data.com/redhat/$basearch"
    action :add
  end
end


template "/etc/td-agent/td-agent.conf" do
  mode "0644"
  source "td-agent.conf.erb"
end

package "td-agent" do
  options value_for_platform(
    ["ubuntu", "debian"] => {"default" => "-f --force-yes"},
    "default" => nil
  )
  action :upgrade
end

service "td-agent" do
  action [ :enable, :start ]
  subscribes :restart, resources(:template => "/etc/td-agent/td-agent.conf")
end

node[:td_agent][:plugins].each do |plugin|
  if plugin.is_a?(Hash)
    plugin_name, plugin_attributes = plugin.first
    fluentd_gem plugin_name do
      plugin true
      %w{action version source options gem_binary}.each do |attr|
        send(attr, plugin_attributes[attr]) if plugin_attributes[attr]
      end
    end
  elsif plugin.is_a?(String)
    fluentd_gem plugin do
      plugin true
    end
  end
end
