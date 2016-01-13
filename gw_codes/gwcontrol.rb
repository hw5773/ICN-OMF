module OmfRc::Util::Gwcontrol
  include OmfRc::ResourceProxyDSL

  SSH = "/usr/bin/ssh"

  work :execute_cmd do |res,cmd,intro_msg,error_msg,success_msg|
    logger.info "#{intro_msg} with: '#{cmd}'"
    result = `#{cmd} 2>&1`
    if $?.exitstatus != 0
      res.log_inform_error "#{error_msg}: '#{result}'"
      false
    else
      logger.info "#{success_msg}: '#{result}'"
      true
    end
  end

  work :prepare_gw  do |res|
#	cmd = "sudo rm /var/lib/dhcp/dhcpd.leases"
#	res.execute_cmd(cmd, "Preparing the experiment", "Failed to prepare", "Progressing (1/5)")
#	cmd = "sudo mv /root/.ssh/known_hosts /root/.ssh/known_hosts.bak"
#	res.execute_cmd(cmd, "Preparing the experiment", "Failed to prepare", "Progressing (2/5)")
#	cmd = "sudo touch /var/lib/dhcp/dhcpd.leases"
#	res.execute_cmd(cmd, "Preparing the experiment", "Failed to prepare", "Progressing (3/5)")
#	cmd = "sudo touch /root/.ssh/known_hosts"
#	res.execute_cmd(cmd, "Preparing the experiment", "Failed to prepare", "Progressing (4/5)")
#	cmd = "/etc/init.d/isc-dhcp-server restart"
#	res.execute_cmd(cmd, "Preparing the experiment", "Failed to prepare", "Progressing (5/5)")
	Dir.mkdir("tmp") unless File.exists? "tmp"
  end

  work :get_ip do |res|
    logger.info "#{res.property.vm_name}'s ip address is #{res.property.manageIP}"
  end

  work :set_ip do |res|
   try_ip = true
   try_num = 0

   while try_ip do
   	cmd = "sudo cp /var/lib/dhcp/dhcpd.leases ./tmp/dhcpd.leases.gw"
   	res.execute_cmd(cmd, "Copying the leases list to get the management ip", "Failed", "Copying is completed")

   	f = File.open("./tmp/dhcpd.leases.gw", "r")
   	ip = []
   	candidate = []
   	for line in f
	   	if line.include? "172"
	   		ip << line
		   end
   		if line.include? "#{res.property.macAddress}"
	   		candidate << ip[-1]
	   	end
        end
	f.close

      	if candidate.length > 0
         	try_ip = false
      	end

      	sleep(3.0)

	try_num = try_num + 1

	if try_num == 12
		cmd = "sudo virsh destroy #{res.property.vm_name}; sudo virsh start #{res.property.vm_name}"
		res.execute_cmd(cmd, "Rebooting the gateway", "Failed", "Rebooting")
		try_num = 0
	end
   end

   g = File.open("./tmp/nodeIPs", "a")
	addr = candidate[-1].split(" ")[1]
   res.property.manageIP = addr

	g.write("#{res.property.sn} #{res.property.manageIP}\n")
	g.close

    logger.info "#{res.property.vm_name}'s ip address is set to #{res.property.manageIP}"
  end

  work :making_ccn_table do |res|
	f = File.open("./tmp/ccnd.conf.gw", "w")
	f.write("add ccnx:/snu.ac.kr udp #{res.property.target_eth_ip}\n")
	f.write("add ccnx:/ccnx.org udp #{res.property.target_eth_ip}\n")
	f.write("add ccnx:/ udp #{res.property.target_eth_ip}\n")
	f.write("add ccnx:/snu.ac.kr tcp #{res.property.target_eth_ip}\n")
	f.write("add ccnx:/ccnx.org tcp #{res.property.target_eth_ip}\n")
	f.write("add ccnx:/ tcp #{res.property.target_eth_ip}\n")

	f.close
  end


	work :get_mac_addr do |res|
		cmd = "sudo cp /etc/libvirt/qemu/#{res.property.vm_name}.xml ./tmp/tmp_#{res.property.vm_name}.xml"
		res.execute_cmd(cmd, "Copy the xml file to the tmp directory", "Failed", "Copy success!")
		xml = open("./tmp/tmp_#{res.property.vm_name}.xml", "r")
		mac = ""

		for line in xml
			if line.include? 'mac address'
				mac = line.split("=")[1][1..-5]
				break
			end
		end

		xml.close

		res.property.macAddress = mac
		logger.info "#{res.property.vm_name}'s mac address is #{res.property.macAddress}"
	end

  work :get_name do |res|
    logger.info "the resource name is #{res.property.vm_name}"
  end

  work :ping_gw do |res|
    start_time = `date +"%s%N`

    cmd = "sshpass -p test #{SSH} -X -o StrictHostKeyChecking=no root@#{res.property.manageIP} \"ping -c 3 172.16.11.1\""
    res.execute_cmd(cmd, "Ping to the gateway", "Failed", "Ping Success!")

    end_time = `date +'%s%N'`
    result = (end_time - start_time) / 1000000
    title = "ping to the gateway three times"
    unit = "ms"
    cmd = "delay #{res.property.server} #{res.property.port} '#{res.property.vm_name}, `date +'%s'`, #{title}, #{result}, #{unit}'"

    logger.info "#{title}: #{result} #{unit}"
  end

  work :ccn_get_node do |res|
    start_time = `date +"%s%N"`
    cmd = "sshpass -p test #{SSH} -o StrictHostKeyChecking=no root@#{res.property.manageIP} \"export PATH=$PATH:/usr/java/jdk1.7.0_07/bin:/usr/local/apache-ant-1.9.4/bin;source /etc/profile;
	ccngetfile -v -unversioned #{res.property.target_file} ./outfile\""
    res.execute_cmd(cmd, "Getting the file from ccnx:/snu.ac.kr", "Failed", "ccnget success!")
    end_time = `date +"%s%N"`
    result = (end_time - start_time) / 1000000
    title = "ccngetfile time from #{res.property.vm_name} #{res.property.target_file}"
    unit = "ms"
    cmd = "delay #{res.property.server} #{res.property.port} '#{res.property.vm_name}, `date +'%s'`, #{title}, #{result}, #{unit}'"

    logger.info "#{title}: #{result} #{unit}"
  end
   
  work :ccn_get_via_gw do |res|
    start_time = `date +"%s%N"`
    cmd = "sshpass -p test #{SSH} -o StrictHostKeyChecking=no root@#{res.property.manageIP} \"export PATH=$PATH:/usr/java/jdk1.7.0_07/bin:/usr/local/apache-ant-1.9.4/bin;source /etc/profile;
	ccngetfile -v -unversioned #{res.property.target_file} ./outfile\""
    res.execute_cmd(cmd, "Getting the file from ccnx:/snu.ac.kr", "Failed", "ccnget success! now it will be sent back")
    cmd = "sshpass -p test #{SSH} -o StrictHostKeyChecking=no root@#{res.property.manageIP} \"sshpass -p #{res.property.back_password} scp -r ./outfile #{res.property.back_id}@#{res.property.back_address}:~/test/outfile\""
    res.execute_cmd(cmd, "Sending the file to #{res.property.back_address}", "Failed", "Sending success!")

    end_time = `date +"%s%N"`
    result = (end_time - start_time) / 1000000
    title = "ccngetfile time from #{res.property.vm_name} #{res.property.target_file}"
    unit = "ms"
    cmd = "delay #{res.property.server} #{res.property.port} '#{res.property.vm_name}, `date +'%s'`, #{title}, #{result}, #{unit}'"

    logger.info "#{title}: #{result} #{unit}"
  end

  work :set_eth_gw do |res|
    success = false

    while !success do
       cmd = "sshpass -p test ssh -o StrictHostKeyChecking=no root@#{res.property.manageIP} ifconfig eth1 #{res.property.eth_ip} netmask 255.255.255.0;"
       success = res.execute_cmd(cmd, "Setting the ip address with " + cmd, "Failed", "Set vm ip success!")
    end
    
    success = false

    while !success do
	    cmd = "sshpass -p test ssh -o StrictHostKeyChecking=no root@#{res.property.manageIP} \"nohup ccndstart > foo.out 2> foo.err < /dev/null &\""
	    success = res.execute_cmd(cmd, "Starting the ccn daemon with #{cmd}", "Failed to start daemon", "#{res.property.vm_name}: Starting the ccn daemon success!")
       logger.info "#{res.property.role} is preparing to start ccn networking"
    end
  end

  work :set_ccn_gw do |res|
    success = false
    
    while !success do
       cmd = "sshpass -p test scp -r -o StrictHostKeyChecking=no ./tmp/ccnd.conf.gw root@#{res.property.manageIP}:/root/.ccnx/ccnd.conf"
       success = res.execute_cmd(cmd, "Setting the ccn configuration file with " + cmd, "Failed", "#{res.property.vm_name}: Set ccn configuration file success!")
    end
  end

  work :video_streaming_gw do |res|
    cmd = "sshpass -p test #{SSH} -X -o StrictHostKeyChecking=no root@#{res.property.manageIP} \"vlc #{res.property.video}\""
    res.execute_cmd(cmd, "Video Streaming Start!", "Failed", "Video Streaming Success!")
  end
end
