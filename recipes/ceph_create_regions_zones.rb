#
# Author:: Hemant Burman <hburman@walmartlabs.com>
# Cookbook Name:: ceph
# Recipe:: ceph_create_regions_zones
#

region = node['ceph']['ceph_federated']['my_region'] #us
zone = node['ceph']['ceph_federated']['my_zone'] #east
this_master_zone = ""
master_endpoint = ""
this_slave_zone = ""
slave_endpoint = ""

node['ceph']['ceph_federated']['regions']["#{region}"]["#{zone}"].each do |master_slave_zone|
	if master_slave_zone['is_master']
		puts "INSIDE"
		this_master_zone = "#{region}-#{zone}-#{master_slave_zone['id']}" 
		master_endpoint = "#{master_slave_zone['endpoints']}:#{master_slave_zone['port']}"
		this_slave_zone = "#{region}-#{master_slave_zone['slave_is']}-#{master_slave_zone['id']}"
		node['ceph']['ceph_federated']['regions'][region][master_slave_zone['slave_is']].each do |temp|
			if !temp['is_master']
				slave_endpoint = "#{temp['endpoints']}:#{temp['port']}"
			end
		end
	end
end

template "#{Chef::Config[:file_cache_path]}/#{region}.json" do
#template "/tmp/#{region}.json" do
	source	'region.json.erb'
	variables(
		:this_master_zone => this_master_zone,
		:this_slave_zone => this_slave_zone,
		:master_endpoint => master_endpoint,
		:slave_endpoint => slave_endpoint
	)
end

