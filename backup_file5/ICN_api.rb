prefix = ""

if ARGV[-6].to_i > 0
	prefix = ARGV[-8]
elsif ARGV[-2].to_i > 0
	prefix = ARGV[-4]
else
	prefix = ARGV[-2]
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

defEvent :prepare_gw_1 do |state|
	state.find_all do |v|
		v[:uid] == 'gwgen' && v[:prepare] && v[:prepare] == 2
	end.size >= 1
end

defEvent :prepare_gw_2 do |state|
	state.find_all do |v|
		v[:uid] == 'gwgen' && v[:prepare] && v[:prepare] == 3
	end.size >= 1
end

defEvent :prepare_gw_3 do |state|
	state.find_all do |v|
		v[:uid] == 'gwgen' && v[:prepare] && v[:prepare] == 4
	end.size >= 1
end

defEvent :prepare_gw_4 do |state|
	state.find_all do |v|
		v[:uid] == 'gwgen' && v[:prepare] && v[:prepare] == 5
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

defEvent :gw_init do |state|
	state.find_all do |v|
		v[:type] == 'gw' && !v[:membership].empty?
	end.size >= 1
end

defEvent :gw_prepared do |state|
	state.find_all do |v|
		v[:type] == 'gw' && v[:stage] && v[:stage] == 2
	end.size >= 1

defEvent :gw_run do |state|
	state.find_all do |v|
		v[:type] == 'gw' && v[:stage] && v[:stage] == 3
	end.size >= 1
end

defEvent :gw_ip_set do |state|
	state.find_all do |v|
		v[:type] == 'gw' && v[:stage] && v[:stage] == 4
	end.size >= 1
end

defEvent :gw_eth_set do |state|
	state.find_all do |v|
		v[:type] == 'gw' && v[:stage] && v[:stage] == 5
	end.size >= 1
end

defEvent :gw_ccn_set do |state|
	state.find_all do |v|
		v[:type] == 'gw' && v[:stage] && v[:stage] == 6
	end.size >= 1
end

defEvent :gw_set do |state|
	state.find_all do |v|
		v[:type] == 'gw' && v[:stage] && v[:stage] == 7
	end.size >= 1
end

def gw_setting(g, from, to)
	g.resources[uid: "gwgen"].act = "gateway_init"

	onEvent :prepare_1 do
#		g.create_resource("gw", type: 'gw', hrn: "gw", uid: "test0", sn: 0, vm_original_clone: "gw", vm_name: "gw"+Time.now.to_i.to_s, eth_ip: from, target_eth_ip: to, action: :clone_from)
		g.create_resource("gw", type: 'gw', hrn: "gw", uid: "gw", sn: 0, vm_original_clone: "gw", vm_name: "gw", eth_ip: from, target_eth_ip: to, action: :attach)


		onEvent :gw_init do
			info "gateway is created"
			info "now get the mac address"
			g.resources[type: "gw", uid: "gw"].action = "get_mac"
		end

		onEvent :gw_prepared do
			info "gateway creating is prepared"
			info "now run the gateway"
			g.resources[type: "gw", uid: "gw"].action = "run"
		end

		onEvent :gw_run do
			info "gateway is run"
			info "now set the management IP to the gateway"

			after 7 do
			g.resources[type: "gw", uid: "gw"].action = "set_ip"
			end
		end

		onEvent :gw_ip_set do 
			info "gateway's management ip is set"
			info "now set the IP address to the ethernet"
			g.resources[type: "gw", uid: "gw"].action = "eth" 
		end

		onEvent :gw_eth_set do
			info "gateway's ethernet ip is set"
x
			info "now set the ccn configuration file"
			g.resources[type: "gw", uid: "gw"].role_set = "gateway"
			g.resources[type: "gw", uid: "gw"].action = "ccn_table"
		end

		onEvent :gw_ccn_set do
			info "gateway's ccn configuration is completed"
			g.resources[type: "gw", uid: "gw"].action = "ccn"
		end
	end
end

def ccn_setting(g, a)
	g.resources[uid: "vmgen"].id = ARGV[-8]
	g.resources[uid: "vmgen"].node = ARGV[-5].to_i
	g.resources[uid: "vmgen"].edge = ARGV[-4].to_i
	g.resources[uid: "vmgen"].subnet = ARGV[-6].to_i

	g.resources[uid: "vmgen"].act = "graph_init"
	onEvent :prepare_1 do
		info "Graph Information Setting Complete."
		if g.resources[uid: "vmgen"].property.mode == 0
			g.resources[uid: "vmgen"].act = "graph_random"
		elsif g.resources[uid: "vmgen"].property.mode == 1
			g.resources[uid: "vmgen"].act = "graph_description"
		else
			g.resources[uid: "vmgen"].act = "plus"
	end

	onEvent :prepare_2 do
		info "Virtual Machine Factory Setting Complete."
		if not g.resources[uid: "vmgen"].mode == 2
			g.resources[uid: "vmgen"].act = "routing_table"
		else
			g.resources[uid: "vmgen"].act = "plus"
		end
	end

	onEvent :prepare_3 do
		arr = (1..ARGV[-5].to_i).to_a
		pub = (1..ARGV[-3].to_i).to_a
		rou = ((ARGV[-3].to_i+1)..(ARGV[-3].to_i+ARGV[-2].to_i)).to_a
		sub = ((ARGV[-3].to_i+ARGV[-2].to_i+1)..(ARGV[-3].to_i+ARGV[-2].to_i+ARGV[-1].to_i))
		prefix = ARGV[-8]
		arr.each do |i|
#			g.create_resource("#{prefix}_#{i}", type: 'vm', hrn: "#{prefix}_#{i}", uid: "#{prefix}_#{i}", sn: i, vm_original_clone: "vm#{i}", vm_name: "#{prefix}_#{i}"+Time.now.to_i.to_s, action: :clone_from)
			g.create_resource("vm#{i}",id: ARGV[-8], password: ARGV[-7], type: 'vm', hrn: "vm#{i}", uid: "#{prefix}_#{i}", sn: i, vm_original_clone: "vm#{i}", vm_name: "vm#{i}", action: :attach)
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

def create_vm(g, c)	
	g.create_resource('vm'+c.to_s, type: 'vm', hrn: 'vm'+c.to_s, uid: 'vm'+c.to_s, vm_name: 'vm'+c.to_s+Time.now.to_i.to_s, sn: c, action: :clone_from)
end

def ping_gw(g, c)
	prefix = 0
	if ARGV[-6].to_i > 0
		prefix = ARGV[-8]
	elsif ARGV[-2].to_i > 0
		prefix = ARGV[-4]
	else
		prefix = ARGV[-2]
	end
	g.resources[type: 'vm', uid: "#{prefix}_#{c}"].action = 'ping_gw'
end

def ping_to(g, c, t)
	prefix = 0
	if ARGV[-6].to_i > 0
		prefix = ARGV[-8]
	elsif ARGV[-2].to_i > 0
		prefix = ARGV[-4]
	else
		prefix = ARGV[-2]
	end

	g.resources[type: 'vm', uid: "#{prefix}_#{c}"].target = t
	g.resources[type: 'vm', uid: "#{prefix}_#{c}"].action = 'ping_to'
end

def ccn_put(g, c, cf)
	prefix = 0
	if ARGV[-6].to_i > 0
		prefix = ARGV[-8]
	elsif ARGV[-2].to_i > 0
		prefix = ARGV[-4]
	else
		prefix = ARGV[-2]
	end

	g.resources[type: 'vm', uid: "#{prefix}_#{c}"].put_file = cf
	g.resources[type: 'vm', uid: "#{prefix}_#{c}"].action = 'ccn_put'
end

def ccn_get(g, c, tf, of)
	prefix = ""
	if ARGV[-6].to_i > 0
		prefix = ARGV[-8]
	elsif ARGV[-2].to_i > 0
		prefix = ARGV[-4]
	else
		prefix = ARGV[-2]
	end

	g.resources[type: 'vm', uid: "#{prefix}_#{c}"].target_file = tf
	g.resources[type: 'vm', uid: "#{prefix}_#{c}"].output_file = of
	g.resources[type: 'vm', uid: "#{prefix}_#{c}"].action = 'ccn_get'
end

def ccn_get_ip(g, c, tf, bid, bpw, baddr)
	prefix = ""
	if ARGV[-6].to_i > 0
		prefix = ARGV[-8]
	elsif ARGV[-2].to_i > 0
		prefix = ARGV[-4]
	else
		prefix = ARGV[-2]
	end

	g.resources[type: 'vm', uid: "#{prefix}_#{c}"].target_file = tf
	g.resources[type: 'vm', uid: "#{prefix}_#{c}"].back_id = bid
	g.resources[type: 'vm', uid: "#{prefix}_#{c}"].back_password = bpw
	g.resources[type: 'vm', uid: "#{prefix}_#{c}"].back_address = baddr
	g.resources[type: 'vm', uid: "#{prefix}_#{c}"].action = 'ccn_get_ip'
end

def ccn_get_ip_gw(g, c, b)
	prefix = ""
	if ARGV[-6].to_i > 0
		prefix = ARGV[-8]
	elsif ARGV[-2].to_i > 0
		prefix = ARGV[-4]
	else
		prefix = ARGV[-2]
	end

	g.resources[type: 'gw', uid: "#{prefix}_#{c}"].back_address = b
	g.resources[type: 'gw', uid: "#{prefix}_#{c}"].action = 'ccn_get_ip'
end
