prefix = ""

if ARGV[-6].to_i > 0
	prefix = ARGV[-7]
elsif ARGV[-2].to_i > 0
	prefix = ARGV[-3]
else
	prefix = ARGV[-1]
end

defEvent :prepare_1 do |state|
	state.find_all do |v|
		v[:uid] == 'vmgen' && v[:prepare] && v[:prepare] == 2
	end.size >= 1
end

defEvent :prepare_2 do |state|
	state.find_all do |v|
		v[:uid] == 'vmgen' && v[:prepare] && v[:prepare] == 3
	end.size >= 1
end

defEvent :prepare_3 do |state|
	state.find_all do |v|
		v[:uid] == 'vmgen' && v[:prepare] && v[:prepare] == 4
	end.size >= 1
end

defEvent :prepare_4 do |state|
	state.find_all do |v|
		v[:uid] == 'vmgen' && v[:prepare] && v[:prepare] == 5
	end.size >= 1
end

defEvent :vm_prepared do |state|
	state.find_all do |v|
		v[:type] == 'vm' && !v[:membership].empty?
	end.size >= ARGV[-5].to_i
end

defEvent :xml_defined do |state|
	state.find_all do |v|
		v[:type] == 'vm' && v[:stage] && v[:stage] == 2
	end.size >= ARGV[-5].to_i
end

defEvent :vm_run do |state|
	state.find_all do |v|
		v[:type] == 'vm' && v[:stage] && v[:stage] == 3
	end.size >= ARGV[-5].to_i
end

defEvent :vm_ip_set do |state|
	state.find_all do |v|
		v[:type] == 'vm' && v[:stage] && v[:stage] == 4
	end.size >= ARGV[-5].to_i
end

defEvent :vm_eth_set do |state|
	state.find_all do |v|
		v[:type] == 'vm' && v[:stage] && v[:stage] == 5
	end.size >= ARGV[-5].to_i
end

defEvent :vm_rt_set do |state|
	state.find_all do |v|
		v[:type] == 'vm' && v[:stage] && v[:stage] == 6
	end.size >= ARGV[-5].to_i
end

defEvent :vm_ccn_table_set do |state|
	state.find_all do |v|
		v[:type] == 'vm' && v[:stage] && v[:stage] == 7
	end.size >= ARGV[-5].to_i
end

defEvent :vm_ccn_set do |state|
	state.find_all do |v|
		v[:type] == 'vm' && v[:stage] && v[:stage] == 8
	end.size >= ARGV[-5].to_i
end

defEvent :gw_prepared do |state|
	state.find_all do |v|
		v[:type] == 'gw' && !v[:membership].empty?
	end.size >= 1
end

defEvent :gw_run do |state|
	state.find_all do |v|
		v[:type] == 'gw' && v[:stage] && v[:stage] == 2
	end.size >= 1
end

defEvent :gw_ip_set do |state|
	state.find_all do |v|
		v[:type] == 'gw' && v[:stage] && v[:stage] == 3
	end.size >= 1
end

defEvent :gw_eth_set do |state|
	state.find_all do |v|
		v[:type] == 'gw' && v[:stage] && v[:stage] == 4
	end.size >= 1
end

defEvent :gw_ccn_set do |state|
	state.find_all do |v|
		v[:type] == 'gw' && v[:stage] && v[:stage] == 5
	end.size >= 1
end

defEvent :gw_set do |state|
	state.find_all do |v|
		v[:type] == 'gw' && v[:stage] && v[:stage] == 6
	end.size >= 1
end

def gw_setting(g, from, to)
	group('request').exec("sudo rm /var/lib/dhcp/dhcpd.leases &")

	after 5 do
		group('request').exec("sudo mv /root/.ssh/known_hosts /root/.ssh/known_hosts.bak &")
	end

	after 10 do
		group('request').exec("sudo touch /var/lib/dhcp/dhcpd.leases &")
	end

	after 15 do
		group('request').exec("/etc/init.d/isc-dhcp-server restart &")
	end

	after 20 do
		group('request').exec("sudo touch /root/.ssh/known_hosts &")
	end

	after 25 do
		g.create_resource("gw", type: 'gw', hrn: "gw", uid: "test0", sn: 0, vm_original_clone: "gw", vm_name: "gw"+Time.now.to_i.to_s, eth_ip: from, target_eth_ip: to, action: :clone_from)

		onEvent :gw_prepared do
			info "gateway creating is prepared"
			info "now run the gateway"
			g.resources[type: "gw", uid: "test0"].action = "run"
		end

		onEvent :gw_run do
			info "gateway is run"
			info "now set the management IP to the gateway"

			after 7 do
			g.resources[type: "gw", uid: "test0"].action = "set_ip"
			end
		end

		onEvent :gw_ip_set do 
			info "gateway's management ip is set"
			info "now set the IP address to the ethernet"
			g.resources[type: "gw", uid: "test0"].action = "eth" 
		end

		onEvent :gw_eth_set do
			info "gateway's ethernet ip is set"
x
			info "now set the ccn configuration file"
			g.resources[type: "gw", uid: "test0"].role_set = "gateway"
			g.resources[type: "gw", uid: "test0"].action = "ccn"
		end

		onEvent :gw_ccn_set do
			info "gateway's ccn configuration is completed"
			group('request').exec("python source_codes/startgw.py 0 &")

			after 60 do
				g.resources[type: "gw", uid: "test0"].action = "complete"
			end
		end
	end
end

def ccn_setting(g, a)
	g.resources[uid: "vmgen"].node = ARGV[-5].to_i
	g.resources[uid: "vmgen"].edge = ARGV[-4].to_i
	g.resources[uid: "vmgen"].subnet = ARGV[-6].to_i

	g.resources[uid: "vmgen"].act = "graph_init"
	onEvent :prepare_1 do
		info "Graph Information Setting Complete."
		g.resources[uid: "vmgen"].act = "graph_random"
	end

	onEvent :prepare_2 do
		info "Virtual Machine Factory Setting Complete."
		g.resources[uid: "vmgen"].act = "routing_table"
	end

	onEvent :prepare_3 do
		arr = (1..ARGV[-5].to_i).to_a
		pub = (1..ARGV[-3].to_i).to_a
		rou = ((ARGV[-3].to_i+1)..(ARGV[-3].to_i+ARGV[-2].to_i)).to_a
		sub = ((ARGV[-3].to_i+ARGV[-2].to_i+1)..(ARGV[-3].to_i+ARGV[-2].to_i+ARGV[-1].to_i))
		prefix = ARGV[-7]
		arr.each do |i|
#			g.create_resource("#{prefix}_#{i}", type: 'vm', hrn: "#{prefix}_#{i}", uid: "#{prefix}_#{i}", sn: i, vm_original_clone: "vm#{i}", vm_name: "#{prefix}_#{i}"+Time.now.to_i.to_s, action: :clone_from)
			g.create_resource("vm#{i}", type: 'vm', hrn: "vm#{i}", uid: "#{prefix}_#{i}", sn: i, vm_original_clone: "vm#{i}", vm_name: "vm#{i}", action: :attach)
		end

		onEvent :vm_prepared do
			info "#{ARGV[-5]} vms creating is prepared"
			info "#{ARGV[-5]} vms are created. Now define them"
			arr.each do |j|
				g.resources[type: 'vm', uid: "#{prefix}_#{j}"].action = "xml_revise"
			end
		end

		onEvent :xml_defined do
			info "#{ARGV[-5]} vms are defined"
			info "Now run them"
			arr.each do |j|
				g.resources[type: 'vm', uid: "#{prefix}_#{j}"].action = "run"
			end
		end

		onEvent :vm_run do
			info "#{ARGV[-5]} vms are run. Now set the manage IPs"
			arr.each do |j|
				g.resources[type: 'vm', uid: "#{prefix}_#{j}"].action = "set_ip"
			end
		end

		onEvent :vm_ip_set do
			info "#{ARGV[-5]} vms' manage IPs are set. Now set ethernet IPs for them"
			
			arr.each do |j|
				g.resources[type: 'vm', uid: "#{prefix}_#{j}"].action = "eth"
			end
		end

		onEvent :vm_eth_set do
			info "#{ARGV[-5]} vms' ethernet IPs are set. Now set routing table for each vms"

			arr.each do |j|
				g.resources[type: 'vm', uid: "#{prefix}_#{j}"].action = "rt"
			end
		end

		onEvent :vm_rt_set do
			info "IP network is created"

			pub.each do |j|
				g.resources[type: 'vm', uid: "#{prefix}_#{j}"].role_set = "publisher"
			end

			rou.each do |j|
				g.resources[type: 'vm', uid: "#{prefix}_#{j}"].role_set = "router"
			end

			sub.each do |j|
				g.resources[type: 'vm', uid: "#{prefix}_#{j}"].role_set = "subscriber"
			end

			arr.each do |j|
				g.resources[type: 'vm', uid: "#{prefix}_#{j}"].action = "ccn_table"
			end
		end

		onEvent :vm_ccn_table_set do
			info "CCN network table is created"

			arr.each do |j|
				g.resources[type: 'vm', uid: "#{prefix}_#{j}"].action = "ccn"
			end
		end
	end			
end

def createRsc(g, c)	
	g.create_resource('vm'+c.to_s, type: 'vm', hrn: 'vm'+c.to_s, uid: 'vm'+c.to_s, vm_name: 'vm'+c.to_s+Time.now.to_i.to_s, sn: c, action: :clone_from)
end

def pingGW(g, c)
	prefix = 0
	if ARGV[-6].to_i > 0
		prefix = ARGV[-7]
	elsif ARGV[-2].to_i > 0
		prefix = ARGV[-3]
	else
		prefix = ARGV[-1]
	end
	g.resources[type: 'vm', uid: "#{prefix}_#{c}"].action = 'ping_gw'
end

def ccnput(g, c)
	prefix = 0
	if ARGV[-6].to_i > 0
		prefix = ARGV[-7]
	elsif ARGV[-2].to_i > 0
		prefix = ARGV[-3]
	else
		prefix = ARGV[-1]
	end
	g.resources[type: 'vm', uid: "#{prefix}_#{c}"].action = 'ccn_put'
end

def ccnget(g, c)
	prefix = ""
	if ARGV[-6].to_i > 0
		prefix = ARGV[-7]
	elsif ARGV[-2].to_i > 0
		prefix = ARGV[-3]
	else
		prefix = ARGV[-1]
	end

	g.resources[type: 'vm', uid: "#{prefix}_#{c}"].action = 'ccn_get'
end

def ccngetip(g, c, b)
	prefix = ""
	if ARGV[-6].to_i > 0
		prefix = ARGV[-7]
	elsif ARGV[-2].to_i > 0
		prefix = ARGV[-3]
	else
		prefix = ARGV[-1]
	end

	g.resources[type: 'vm', uid: "#{prefix}_#{c}"].back_address = b
	g.resources[type: 'vm', uid: "#{prefix}_#{c}"].action = 'ccn_get_ip'
end

def ccngetipgw(g, c, b)
	prefix = ""
	if ARGV[-6].to_i > 0
		prefix = ARGV[-7]
	elsif ARGV[-2].to_i > 0
		prefix = ARGV[-3]
	else
		prefix = ARGV[-1]
	end

	g.resources[type: 'gw', uid: "#{prefix}_#{c}"].back_address = b
	g.resources[type: 'gw', uid: "#{prefix}_#{c}"].action = 'ccn_get_ip'
end
