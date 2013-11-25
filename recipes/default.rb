#
# Cookbook Name:: fluentd
# Recipe:: default
#
# Copyright 2011, Treasure Data, Inc.
#

package 'libpq-dev' do
  action :install
end

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
  recursive true
  action :create
end

package "libssl0.9.8" do
  action :install
end

case node['platform']
when "ubuntu"
  dist = node['lsb']['codename']
  if dist == 'raring' 
    package "td-agent" do
      version "#{node['td_agent']['version']}"
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

search("users", "id:kwarter") do |u|
  template "/etc/td-agent/td-agent.conf" do
    mode "0644"
    source "td-agent.conf.erb"
    variables(
          :access_key    => u['access_key'],
          :access_secret => u['access_secret']
    )
  end
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
