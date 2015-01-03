#
# Author:: Hemant Burman <hemant.burman@gmail.com>
# Cookbook Name:: ceph
# Recipe:: ceph_region_zone_sync
#

sync_conf_path = node['ceph']['ceph_federated']['sync_conf_path']

secret_key = node['ceph']['ceph_federated']['secret_key']
access_key = node['ceph']['ceph_federated']['access_key']

region = node['ceph']['ceph_federated']['my_region'] #us-1
zone = node['ceph']['ceph_federated']['my_zone'] #east
region_secondary = node['ceph']['ceph_federated']['my_region_secondary'] #us-2

master_zone = ""
master_endpoint = ""
slave_zone = ""
slave_endpoint = ""

secondary_master_zone = ""
secondary_master_endpoint = ""
secondary_slave_zone = ""
secondary_slave_endpoint = ""



directory "#{node['ceph']['ceph_federated']['sync_conf_path']}" do
	owner	'root'
	group	'root'
	mode	'0755'
	recursive true
end

#Creating Zone Sync Files

node['ceph']['ceph_federated']['regions'][region][zone].each do |master_slave_zone|
	if master_slave_zone['is_master']
		master_zone = "#{region}-#{zone}-#{master_slave_zone['id']}"
		master_endpoint = "#{master_slave_zone['endpoints']}:#{master_slave_zone['port']}"
		slave_zone = "#{region}-#{master_slave_zone['slave_is']}-#{master_slave_zone['id']}"
		node['ceph']['ceph_federated']['regions'][region][master_slave_zone['slave_is']].each do |temp|
			if temp['slave_of'].eql? zone
				slave_endpoint = "#{temp['endpoints']}:#{temp['port']}"
			end	
		end
	elsif !master_slave_zone['is_master']
		master_zone = "#{region}-#{master_slave_zone['slave_of']}-#{master_slave_zone['id']}"
		node['ceph']['ceph_federated']['regions'][region][master_slave_zone['slave_of']].each do |temp|
			if temp['slave_is'].eql? zone
				master_endpoint = "#{temp['endpoints']}:#{temp['port']}"
			end
		slave_zone = "#{region}-#{zone}-#{master_slave_zone['id']}"
		slave_endpoint = "#{master_slave_zone['endpoints']}:#{master_slave_zone['port']}"
		end
	end
end

if !region_secondary.nil?
        node['ceph']['ceph_federated']['regions']["#{region_secondary}"]["#{zone}"].each do |secondary_region_master_slave_zone|
                if secondary_region_master_slave_zone['is_master']
                        secondary_master_zone = "#{region_secondary}-#{zone}-#{secondary_region_master_slave_zone['id']}" #eu-1-west-1
                        secondary_master_endpoint = "#{secondary_region_master_slave_zone['endpoints']}:#{secondary_region_master_slave_zone['port']}"
                        secondary_slave_zone = "#{region_secondary}-#{secondary_region_master_slave_zone['slave_is']}-#{secondary_region_master_slave_zone['id']}" #eu-1-east-1
                        node['ceph']['ceph_federated']['regions'][region_secondary][secondary_region_master_slave_zone['slave_is']].each do |temp|
                                if temp['slave_of'].eql? zone
                                        secondary_slave_endpoint = "#{temp['endpoints']}:#{temp['port']}"
                                end
                        end
                elsif !secondary_region_master_slave_zone['is_master']
                        secondary_master_zone = "#{region_secondary}-#{secondary_region_master_slave_zone['slave_of']}-#{secondary_region_master_slave_zone['id']}" #eu-1-west-1
                        node['ceph']['ceph_federated']['regions'][region_secondary][secondary_region_master_slave_zone['slave_of']].each do |temp|
                                if temp['slave_is'].eql? zone
                                        secondary_master_endpoint = "#{temp['endpoints']}:#{temp['port']}" #us-1-west-1
                                end
                        secondary_slave_zone = "#{region_secondary}-#{zone}-#{secondary_region_master_slave_zone['id']}"
                        secondary_slave_endpoint = "#{secondary_region_master_slave_zone['endpoints']}:#{secondary_region_master_slave_zone['port']}"
                        end
                end
        end
end


#Create Conf File for Sync
template "#{node['ceph']['ceph_federated']['sync_conf_path']}/zone_sync_#{master_zone}-#{slave_zone}.conf" do
	source "zone_sync.conf.erb"
	variables(
		:master_zone          => master_zone,
		:slave_zone           => slave_zone,
		:source_zone_endpoint => master_endpoint,
		:dest_zone_endpoint   => slave_endpoint,
		:access_key           => access_key,
		:secret_key           => secret_key
	)
end

template "#{node['ceph']['ceph_federated']['sync_conf_path']}/zone_sync_#{secondary_master_zone}-#{secondary_slave_zone}.conf" do
        source "zone_sync.conf.erb"
        variables(
		:master_zone          => secondary_master_zone,
		:slave_zone           => secondary_slave_zone,
                :source_zone_endpoint => secondary_master_endpoint,
                :dest_zone_endpoint   => secondary_slave_endpoint,
                :access_key           => access_key,
                :secret_key           => secret_key
        )
	only_if { region_secondary }
end 


#Creating Inter Region Sync File
master_region_endpoint = master_endpoint
secondary_region_endpoint = secondary_master_endpoint

if !node['ceph']['ceph_federated']['regions'][region]['is_master']
	master_region_endpoint = secondary_master_endpoint
	secondary_region_endpoint = master_endpoint
end
template "#{node['ceph']['ceph_federated']['sync_conf_path']}/region_sync_#{master_zone}-#{secondary_master_zone}.conf" do
        source "zone_sync.conf.erb"
        variables(
		:master_zone          => master_zone,
		:slave_zone           => secondary_master_zone,
                :source_zone_endpoint => master_region_endpoint,
                :dest_zone_endpoint   => secondary_region_endpoint,
                :access_key           => access_key,
                :secret_key           => secret_key
        )
	only_if { region_secondary }
end 
