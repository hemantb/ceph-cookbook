#
# Author:: Hemant Burman <hemant.burman@gmail.com>
# Cookbook Name:: ceph
# Recipe:: ceph_federated
#
node.default['ceph']['is_radosgw'] = true
region = node['ceph']['ceph_federated']['my_region']
zone = node['ceph']['ceph_federated']['my_zone']
region_secondary = node['ceph']['ceph_federated']['my_region_secondary'] #us-2

include_recipe 'ceph::_common'
include_recipe 'ceph::radosgw_install'
include_recipe 'ceph::conf'
include_recipe 'ceph::create_federated_buckets'

directory '/var/log/radosgw' do
  owner node['apache']['user']
  group node['apache']['group']
  mode '0755'
  action :create
end


file '/var/log/radosgw/radosgw.log' do
  owner node['apache']['user']
  group node['apache']['group']
end

directory '/var/run/ceph-radosgw' do
  owner node['apache']['user']
  group node['apache']['group']
  mode '0755'
  action :create
end

if node['ceph']['radosgw']['webserver_companion']
  include_recipe "ceph::radosgw_#{node['ceph']['radosgw']['webserver_companion']}"
end

node['ceph']['ceph_federated']['regions']["#{region}"]["#{zone}"].each do |master_slave_zone|
	ceph_myclient "radosgw.#{region}-#{zone}-#{master_slave_zone['id']}" do
  		caps('mon' => 'allow rwx', 'osd' => 'allow rwx')
  		owner 'root'
  		group node['apache']['group']
  		mode 0640
	end
	directory "/var/lib/ceph/radosgw/ceph-radosgw.#{region}-#{zone}-#{master_slave_zone['id']}" do
		recursive true
		only_if { node['platform'] == 'ubuntu' }
	end
end

if !region_secondary.nil?
node['ceph']['ceph_federated']['regions']["#{region_secondary}"]["#{zone}"].each do |master_slave_zone|
        ceph_myclient "radosgw.#{region_secondary}-#{zone}-#{master_slave_zone['id']}" do
                caps('mon' => 'allow rwx', 'osd' => 'allow rwx')
                owner 'root'
                group node['apache']['group']
                mode 0640
        end
        directory "/var/lib/ceph/radosgw/ceph-radosgw.#{region_secondary}-#{zone}-#{master_slave_zone['id']}" do
                recursive true
                only_if { node['platform'] == 'ubuntu' }
        end
end
end
