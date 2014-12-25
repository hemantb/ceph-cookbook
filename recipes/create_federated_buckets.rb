
# Author:: Hemant Burman <hemant.burman@gmail.com>
# Cookbook Name:: ceph
# Recipe:: create_federated_buckets


pre_tag_name = "bucket_setup_started"
post_tag_name = "bucket_setup_completed"
region = node['ceph']['ceph_federated']['my_region']
region_secondary = node['ceph']['ceph_federated']['my_region_secondary']
zone = node['ceph']['ceph_federated']['my_zone']
setup_running = search(:node, "tags:#{pre_tag_name} AND chef_environment:#{node.chef_environment}")

#if ((setup_running.empty? || tagged?("#{pre_tag_name}")) && (! tagged?("#{post_tag_name}")))
#	tag("#{pre_tag_name}")
	node['ceph']['ceph_federated']['bucket_names'].each do |bucket|
		node['ceph']['ceph_federated']['regions'][region][zone].each do |master_slave_zone|
			execute 'creating all the buckets needed for federated ceph' do
				Chef::Log.info("ceph osd pool create .#{region}-#{zone}-#{master_slave_zone['id']}#{bucket} #{node['ceph']['pg_num']} #{node['ceph']['pgp_num']}")
				command "ceph osd pool create .#{region}-#{zone}-#{master_slave_zone['id']}#{bucket} #{node['ceph']['pg_num']} #{node['ceph']['pgp_num']}"
			end
		end
                if !region_secondary.nil?
                        node['ceph']['ceph_federated']['regions'][region_secondary][zone].each do |secondary_region_master_slave_zone|
				execute 'creating all the buckets needed for me as secondary region' do
                                	Chef::Log.info("ceph osd pool create .#{region_secondary}-#{zone}-#{secondary_region_master_slave_zone['id']}#{bucket} #{node['ceph']['pg_num']} #{node['ceph']['pgp_num']}")
                                	command "ceph osd pool create .#{region_secondary}-#{zone}-#{secondary_region_master_slave_zone['id']}#{bucket} #{node['ceph']['pg_num']} #{node['ceph']['pgp_num']}"
				end
                        end
                end
#	tag("#{post_tag_name}")	
	end
#elsif (setup_running.count > 1)
#	untag("#{tag_name}")
#end
