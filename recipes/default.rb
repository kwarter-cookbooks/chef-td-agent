#
# Cookbook Name:: fluentd
# Recipe:: default
#
# Copyright 2011, Treasure Data, Inc.
#

package 'libpq-dev' do
  action :install
end

Chef::Recipe.send(:include, TdAgent::Version)
Chef::Provider.send(:include, TdAgent::Version)

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

  #
  # HACK on action:
  #
  # 1.x versions are not supported on Trusty and 2.0 version have issues while pg gem (Ruby 2.1)
  dist = 'squeeze' if dist == 'trusty'

  source =
    if major.nil? || major == '1'
      # version 1.x or no version
      if dist == 'precise'
        'http://packages.treasuredata.com/precise/'
      else
        'http://packages.treasuredata.com/debian/'
      end
    else
      # version 2.x or later
      "http://packages.treasuredata.com/#{major}/ubuntu/#{dist}/"
    end

  apt_repository "treasure-data" do
    uri source
    distribution dist
    components ["contrib"]
    key "http://packages.treasuredata.com/GPG-KEY-td-agent"
    action :add
  end
when "centos", "redhat", "amazon"
  yum_repository "treasure-data" do
    url "http://packages.treasuredata.com/redhat/$basearch"
    gpgkey "http://packages.treasuredata.com/GPG-KEY-td-agent"
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

if node['td_agent']['includes']
  directory "/etc/td-agent/conf.d" do
    mode "0755"
  end
end

package "td-agent" do
  if node[:td_agent][:pinning_version]
    action :install
    version node[:td_agent][:version]
  else
    action :upgrade
  end
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

service "td-agent" do
  action [ :enable, :start ]
  subscribes :restart, resources(:template => "/etc/td-agent/td-agent.conf")
end
