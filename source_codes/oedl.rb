require './ICN_api'

def_property('vmgen', 'vmgen', 'Name of vmgen')

defGroup('init', 'mbox1@mbox1')
defGroup('request', 'mbox2@mbox1')
defGroup('vmgens', prop.vmgen)

defEvent :vm_prepared do |state|
	state.find_all do |v|
		v[:type] == 'vm' && !v[:membership].empty?
	end.size >= ARGV[-5].to_i
end

defEvent :vm_run do |state|
	state.find_all do |v|
		v[:type] == 'vm' && v[:stage] && v[:stage] == 2
	end.size >= ARGV[-5].to_i
end

defEvent :vm_ip_set do |state|
	state.find_all do |v|
		v[:type] == 'vm' && v[:stage] && v[:stage] == 3
	end.size >= ARGV[-5].to_i
end

defEvent :vm_eth_set do |state|
	state.find_all do |v|
		v[:type] == 'vm' && v[:stage] && v[:stage] == 4
	end.size >= ARGV[-5].to_i
end

defEvent :vm_rt_set do |state|
	state.find_all do |v|
		v[:type] == 'vm' && v[:stage] && v[:stage] == 5
	end.size >= ARGV[-5].to_i
end

defEvent :vm_ccn_set do |state|
	state.find_all do |v|
		v[:type] == 'vm' && v[:stage] && v[:stage] == 6
	end.size >= ARGV[-5].to_i
end

defEvent :vm_set do |state|
	state.find_all do |v|
		v[:type] == 'vm' && v[:stage] && v[:stage] == 7
	end.size >= ARGV[-5].to_i
end

onEvent :ALL_UP do
	group('init').exec("./source_codes/graph.sh #{ARGV[-5]} #{ARGV[-4]} &" ) 

	after 5 do
		group('init').exec("sudo rm /var/lib/dhcp/dhcpd.leases &")
	end

	after 10 do
		group('init').exec("sudo mv /root/.ssh/known_hosts /root/.ssh/known_hosts.bak &")
	end

	after 15 do
		group('init').exec("sudo touch /var/lib/dhcp/dhcpd.leases &")
	end

	after 20 do
		group('init').exec("/etc/init.d/isc-dhcp-server restart &")
	end

	after 25 do
		group('init').exec("sudo touch /root/.ssh/known_hosts &")
	end

	after 30 do
		group('init').exec("python ./source_codes/analysis.py #{ARGV[-5]} &")
	end

	after 35 do
		group('init').exec("python ./source_codes/routing.py #{ARGV[-5]} &")
	end

	after 40 do
		group('init').exec("python ./source_codes/ccnd.py #{ARGV[-3]} #{ARGV[-2]} #{ARGV[-1]} &")
	end

	after 45 do
		group('vmgens') do |g|
			g.create_resource('test1', type: 'vm', hrn: 'test1', uid: 'test1', sn: 1, vm_name: 'test1'+Time.now.to_i.to_s, action: :clone_from)
			g.create_resource('test2', type: 'vm', hrn: 'test2', uid: 'test2', sn: 2, vm_name: 'test2'+Time.now.to_i.to_s, vm_original_clone: 'vm2', action: :clone_from)
			g.create_resource('test3', type: 'vm', hrn: 'test3', uid: 'test3', sn: 3, vm_name: 'test3'+Time.now.to_i.to_s, vm_original_clone: 'vm3', action: :clone_from)

			onEvent :vm_prepared do
				info "#{ARGV[-5]} vms creating is prepared"
				info "#{ARGV[-5]} vms are created. Now run them"
				group('init').exec("python ./source_codes/xmlgen.py #{ARGV[-5]} &")
				after 30 do
					g.resources[type: 'vm', uid: 'test1'].action = "run"
					after 3 do
						g.resources[type: 'vm', uid: 'test2'].action = "run"
					end
					after 6 do
						g.resources[type: 'vm', uid: 'test3'].action = "run"
					end
				end
			end

			onEvent :vm_run do
				info "#{ARGV[-5]} vms are run. Now set the manage IPs"
				g.resources[type: 'vm', uid: 'test1'].action = "set_ip"
				after 3 do
					g.resources[type: 'vm', uid: 'test2'].action = "set_ip"
				end
				after 6 do
					g.resources[type: 'vm', uid: 'test3'].action = "set_ip"
				end
			end

			onEvent :vm_ip_set do
				info "#{ARGV[-5]} vms' manage IPs are set. Now set ethernet IPs for them"
				g.resources[type: 'vm', uid: 'test1'].action = "eth"
				g.resources[type: 'vm', uid: 'test2'].action = "eth"
				g.resources[type: 'vm', uid: 'test3'].action = "eth"
			end

			onEvent :vm_eth_set do
				info "#{ARGV[-5]} vms' ethernet IPs are set. Now set routing table for each vms"
				g.resources[type: 'vm', uid: 'test1'].action = "rt"
				g.resources[type: 'vm', uid: 'test2'].action = "rt"
				g.resources[type: 'vm', uid: 'test3'].action = "rt"
			end

			onEvent :vm_rt_set do
				info "IP network is created"
				g.resources[type: 'vm', uid: 'test1'].role_set = "publisher"
				g.resources[type: 'vm', uid: 'test2'].role_set = "router"
				g.resources[type: 'vm', uid: 'test3'].role_set = "subscriber"
				g.resources[type: 'vm', uid: 'test1'].action = "ccn"
				g.resources[type: 'vm', uid: 'test2'].action = "ccn"
				g.resources[type: 'vm', uid: 'test3'].action = "ccn"
			end

			onEvent :vm_ccn_set do
				info "Generating CCN overlay network"
				group('init').exec("python ./source_codes/setccnd.py #{ARGV[-3]} #{ARGV[-2]} #{ARGV[-1]} &")
				after 10 do
					g.resources[type: 'vm', uid: 'test1'].action = "complete"
				end
				after 20 do
					g.resources[type: 'vm', uid: 'test2'].action = "complete"
				end
				after 30 do
					g.resources[type: 'vm', uid: 'test3'].action = "complete"
				end
			end

			onEvent :vm_set do
				info "Testing the CCN networking"
				pingGW(g, 1)
				pingGW(g, 2)
				pingGW(g, 3)

				after 5 do
					ccnput(g, 1)
				end

				after 10 do
					ccngetip(g, 2, "210.114.88.7")
				end

				after 30 do
					ccnget(g, 3)
#					ccnget(g, 3)
				end

				after 35 do
					group('init').exec("./source_codes/clean.sh")
				end

				after 40 do
					done!
				end
			end
		end
	end
end
