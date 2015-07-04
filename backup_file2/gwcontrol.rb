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

  work :get_ip do |res|
    logger.info "#{res.property.vm_name}'s ip address is #{res.property.manageIP}"
  end

  work :set_ip do |res|
    file = File.new("./nodeIPs")
    
    n = res.property.sn.to_i

    d = {}
    file.each do |line|
      lst = line.split
      d[lst[0].to_i] = lst[1]
    end

    res.property.manageIP = d[n]

    logger.info "#{res.property.vm_name}'s ip address is set to #{res.property.manageIP}"
    file.close
  end

  work :get_name do |res|
    logger.info "the resource name is #{res.property.vm_name}"
  end

  work :ping_gw do |res|
    cmd = "sshpass -p test #{SSH} -o StrictHostKeyChecking=no root@#{res.property.manageIP} \"ping -c 3 172.16.11.1\""
    res.execute_cmd(cmd, "Ping to the gateway", "Failed", "Ping success!")
  end

  work :ccn_get_file do |res|
    cmd = "sshpass -p test #{SSH} -o StrictHostKeyChecking=no root@#{res.property.manageIP} \"export PATH=$PATH:/usr/java/jdk1.7.0_07/bin:/usr/local/apache-ant-1.9.4/bin;source /etc/profile;ccngetfile ccnx:/snu.ac.kr/test ./testfile\""
    res.execute_cmd(cmd, "Getting the file from ccnx:/snu.ac.kr", "Failed", "ccnget success!")
  end

  work :ccn_get_ip do |res|
    cmd = "sshpass -p test #{SSH} -o StrictHostKeyChecking=no root@#{res.property.manageIP} \"export PATH=$PATH:/usr/java/jdk1.7.0_07/bin:/usr/local/apache-ant-1.9.4/bin;source /etc/profile;ccngetfile ccnx:/snu.ac.kr/test ./testfile\""
    res.execute_cmd(cmd, "Getting the file from ccnx:/snu.ac.kr", "Failed", "ccnget success! now it will be sent back")
    cmd = "sshpass -p test #{SSH} -o StrictHostKeyChecking=no root@#{res.property.manageIP} \"sshpass -p mmlab2015 scp -r ./testfile dhkim@#{res.property.back}:~/test/testfile\""
    res.execute_cmd(cmd, "Sending the file to #{res.property.back}", "Failed", "Sending success!")
  end

  work :set_eth_gw do |res|
    cmd = "ifconfig eth1 #{res.property.eth_ip} netmask 255.255.255.0;"
    res.execute_cmd(cmd, "Setting the ip address with " + cmd, "Failed", "Set vm ip success!")
  end

  work :set_ccn_gw do |res|
    f = File.new("ccnd.conf.gw", "w")
    f.write("add ccnx:/ udp #{res.property.target_eth_ip}\n")
    sleep 5
    cmd = "sshpass -p test scp -r ccnd.conf.gw root@#{res.property.manageIP}:/root/.ccnx/ccnd.conf"
    res.execute_cmd(cmd, "Setting the ccn configuration file with " + cmd, "Failed", "#{res.property.vm_name}: Set ccn configuration file success!")
    logger.info "#{res.property.role} is preparing to start ccn networking"
    f.close
  end
end
