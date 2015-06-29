def ccn_setting(g, a)

	group('init').exec("sudo ./source_codes/clean.sh")
	after 2 do
		group('init').exec("sudo ./source_codes/graph.sh " + a[-5] + " " + a[-4])
		info "Make the random graph"	
	end

	after 5 do
		group('init').exec("sudo python ./source_codes/analysis.py")
		info "Graph analysis is completed."
	end
	
	after 10 do
		group('init').exec("sudo python ./source_codes/routing.py " + a[-5])
		info "Making the routing table is completed."
	end


	puts "now we are going to generate #{a[-5]} VMs."
	arr = (1..a[-5].to_i).to_a
	arr.each do |i|
		after 45 * (i-1) do
			createRsc(g, i)
		end
	end

	t = a[-5].to_i

	after 50 * t do
		group('init').exec("sudo python ./source_codes/xmlgen.py #{a[-5]}")
	end

	after 50 * t + 15 do
		group('init').exec("sudo rm /var/lib/dhcp/dhcpd.leases")

		after 1 do
			group('init').exec("sudo touch /var/lib/dhcp/dhcpd.leases")
		end

		after 2 do
			group('init').exec("/etc/init.d/isc-dhcp-server restart")
		end
	end

	after 50 * t + 25 do
		arr.each do |j|
			after 7 * j do
				vm = g.resources[type: 'vm', hrn: 'vm'+j.to_s]
				vm.action = 'run'
			end
		end
	end

	after 57 * t + 30 do
		arr.each do |j|
			after 5 * j do
				vm = g.resources[type: 'vm', hrn: 'vm'+j.to_s]
				vm.action = 'set_ip'
			end
		end

		group('init').exec("sudo mv /root/.ssh/known_hosts /root/.ssh/known_hosts.bak")
		group('init').exec("sudo python ./source_codes/ccnd.py #{a[-3]} #{a[-2]} #{a[-1]}")
		info "Making the ccnd configure file is completed."
	end
	
	after 57 * (t + 1) do
		group('init').exec("sudo python ./source_codes/test.py")
	end

	after 57 * (t + 1) + 10 do
		arr.each do |j|
			vm = g.resources[type: 'vm', hrn: 'vm'+j.to_s]
	#		vm.action = 'eth'
		end
		group('init').exec("sudo python ./source_codes/setccnd.py #{a[-3]} #{a[-2]} #{a[-1]}")
		info "Setting the ccnd configure file for each node is completed."
	end

	after 57 * (t + 3) do
		group('init').exec("sudo python ./source_codes/setRTs.py #{a[-5]}")
		info "Setting the Routing Table for each node is completed."
	end

	after 57 * (t + 4) do
		group('init').exec("sudo python ./source_codes/setIPs.py")
	#	group('init').exec("sudo python /home/dhkim/testbed/setccnd.py #{a[-3]} #{a[-2]} #{a[-1]}")
		info "Setting the ip address for each node is completed."
	end

	after 57 * (t + 2) do
		arr.each do |j|
			if j < a[-3].to_i
				g.resources[type: 'vm', hrn: 'vm'+j.to_s].role = "publisher"
			elsif j < a[-2].to_i
				g.resources[type: 'vm', hrn: 'vm'+j.to_s].role = "router"
			else
				g.resources[type: 'vm', hrn: 'vm'+j.to_s].role = "subscriber"
			end
		end
	end			
end

def createRsc(g, c)
	
	g.create_resource('vm'+c.to_s, type: 'vm', hrn: 'vm'+c.to_s, uid: 'vm'+c.to_s, vm_name: 'vm'+c.to_s+Time.now.to_i.to_s, sn: c, action: :clone_from)
end

def pingGW(g, c)
	g.resources[type: 'vm', uid: 'vm'+c.to_s].action = 'ping_gw'
end

def ccnput(g, c)
	g.resources[type: 'vm', uid: 'vm'+c.to_s].action = 'ccn_put'
end

def ccnget(g, c)
	g.resources[type: 'vm', uid: 'vm'+c.to_s].action = 'ccn_get'
end
