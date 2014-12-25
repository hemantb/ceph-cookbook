#
# Author:: Hemant Burman <hemant.burman@gmail.com>
# Cookbook Name:: ceph
# Recipe:: ceph_create_regions_zones
#

region = node['ceph']['ceph_federated']['my_region'] #us-1
zone = node['ceph']['ceph_federated']['my_zone'] #east
region_secondary = node['ceph']['ceph_federated']['my_region_secondary'] #us-2

puts "############################"
puts region
puts zone

this_master_zone = ""
master_endpoint = ""
this_slave_zone = ""
slave_endpoint = ""

this_secondary_master_zone = ""
secondary_master_endpoint = ""
this_secondary_slave_zone = ""
secondary_slave_endpoint = ""

#Declaring Variables for Region:us-1 which is master Region and secondary counterpart is Region:eu-1 
node['ceph']['ceph_federated']['regions']["#{region}"]["#{zone}"].each do |master_slave_zone|
	if master_slave_zone['is_master']
		this_master_zone = "#{region}-#{zone}-#{master_slave_zone['id']}" #us-1-east-1
		master_endpoint = "#{master_slave_zone['endpoints']}:#{master_slave_zone['port']}" 
		this_slave_zone = "#{region}-#{master_slave_zone['slave_is']}-#{master_slave_zone['id']}" #us-1-west-1
		node['ceph']['ceph_federated']['regions'][region][master_slave_zone['slave_is']].each do |temp|
			#slave_endpoint = "#{temp['endpoints']}:#{temp['port']}" if ! temp['is_master']		
			if !temp['is_master']
				slave_endpoint = "#{temp['endpoints']}:#{temp['port']}"
			end
		end
	end
end

#Declaring Variables for Region:us-2 which is secondary for Region:eu-2
if !region_secondary.nil?
	node['ceph']['ceph_federated']['regions'][region_secondary][zone].each do |secondary_region_master_slave_zone|
		if secondary_region_master_slave_zone['is_master']
			this_secondary_master_zone = "#{region_secondary}-#{zone}-#{secondary_region_master_slave_zone['id']}" #us-2-east-1		
			secondary_master_endpoint = "#{secondary_region_master_slave_zone['endpoints']}:#{secondary_region_master_slave_zone['port']}"
			this_secondary_slave_zone = "#{region_secondary}-#{secondary_region_master_slave_zone['slave_is']}-#{secondary_region_master_slave_zone['id']}" #us-2-west-1
			node['ceph']['ceph_federated']['regions'][region_secondary][secondary_region_master_slave_zone['slave_is']].each do |temp|
				if !temp['is_master']
					secondary_slave_endpoint = "#{temp['endpoints']}:#{temp['port']}"
				end
			end
		end
	end		
end



puts this_master_zone
puts this_slave_zone
puts master_endpoint
puts slave_endpoint
#Create Master Region File us-1.json
template "#{Chef::Config[:file_cache_path]}/#{region}.json" do
	source	'region.json.erb'
	variables(
		:this_master_zone => this_master_zone,
		:this_slave_zone => this_slave_zone,
		:master_endpoint => master_endpoint,
		:slave_endpoint => slave_endpoint,
		:region_name => region,
		:region_is_master => "true"
	)
end

#Create Secondary Region File us-2.json
template "#{Chef::Config[:file_cache_path]}/#{region_secondary}.json" do
	source  'region.json.erb'
	variables(
                :this_master_zone => this_secondary_master_zone,
                :this_slave_zone => this_secondary_slave_zone,
                :master_endpoint => secondary_master_endpoint,
                :slave_endpoint => secondary_slave_endpoint,
		:region_name => region_secondary,
		:region_is_master => "false"
	)
	only_if	{ region_secondary }
end

#Create Regions us-1 as Master Region for eu-1 and us-2 as secondary region for eu-2
execute "adding region #{region}" do
	Chef::Log.info("radosgw-admin region set --infile #{Chef::Config[:file_cache_path]}/#{region}.json --name client.radosgw.#{region}-#{zone}-#{node['ceph']['ceph_federated']['regions'][region][zone][0]['id']}; rados -p .us.rgw.root rm region_info.default; radosgw-admin region default --rgw-region=#{region} --name client.radosgw.#{region}-#{zone}-#{node['ceph']['ceph_federated']['regions'][region][zone][0]['id']}; radosgw-admin regionmap update --name client.radosgw.#{region}-#{zone}-#{node['ceph']['ceph_federated']['regions'][region][zone][0]['id']}")

	command "radosgw-admin region set --infile #{Chef::Config[:file_cache_path]}/#{region}.json --name client.radosgw.#{region}-#{zone}-#{node['ceph']['ceph_federated']['regions'][region][zone][0]['id']}; rados -p .us.rgw.root rm region_info.default; radosgw-admin region default --rgw-region=#{region} --name client.radosgw.#{region}-#{zone}-#{node['ceph']['ceph_federated']['regions'][region][zone][0]['id']}; radosgw-admin regionmap update --name client.radosgw.#{region}-#{zone}-#{node['ceph']['ceph_federated']['regions'][region][zone][0]['id']}"
end

execute "adding region #{region_secondary}" do
	Chef::Log.info("radosgw-admin region set --infile #{Chef::Config[:file_cache_path]}/#{region_secondary}.json --name client.radosgw.#{region_secondary}-#{zone}-#{node['ceph']['ceph_federated']['regions'][region_secondary][zone][0]['id']};rados -p .us.rgw.root rm region_info.default;radosgw-admin regionmap update --name client.radosgw.#{region_secondary}-#{zone}-#{node['ceph']['ceph_federated']['regions'][region_secondary][zone][0]['id']}")
	
	command "radosgw-admin region set --infile #{Chef::Config[:file_cache_path]}/#{region_secondary}.json --name client.radosgw.#{region_secondary}-#{zone}-#{node['ceph']['ceph_federated']['regions'][region_secondary][zone][0]['id']};radosgw-admin regionmap update --name client.radosgw.#{region_secondary}-#{zone}-#{node['ceph']['ceph_federated']['regions'][region_secondary][zone][0]['id']}"
end
