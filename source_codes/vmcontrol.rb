module OmfRc::Util::Vmcontrol
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

  work :prepare do |res|
    cmd = "sudo rm /var/lib/dhcp/dhcpd.leases"
    res.execute_cmd(cmd, "Preparing the experiment", "Failed to prepare", "Progressing (1/5)")
    cmd = "sudo mv /root/.ssh/known_hosts /root/.ssh/known_hosts.bak"
    res.execute_cmd(cmd, "Preparing the experiment", "Failed to prepare", "Progressing (2/5)")
    cmd = "sudo touch /var/lib/dhcp/dhcpd.leases"
    res.execute_cmd(cmd, "Preparing the experiment (3/5)", "Failed to prepare", "Progressing (3/5)")
#    cmd = "sudo touch /root/.ssh/known_hosts"
#    res.execute_cmd(cmd, "Preparing the experiment (4/5)", "Failed to prepare", "Progressing (4/5)")
    cmd = "/etc/init.d/isc-dhcp-server restart"
    res.execute_cmd(cmd, "Preparing the experiment on going (5/5)", "Failed to prepare", "Progressing (5/5)")
  end

  work :making_tables do |res|
    logger.info "Now analysis the graph"

    graph = File.open("./tmp/graph", "r")
    numOfVMs = res.property.node
    subnet = res.property.subnet

    g = []
    h = []

    for i in 1..numOfVMs
        g << File.open("./tmp/vmIP.#{i}", "w")
        h << File.open("./tmp/port.#{i}", "w")
    end

    n = graph.gets[0..-2].to_i
    path = []
    numOfVMs.times { path << [] }

    for line in graph
        a = line.split(" ")
        a1 = a[0].to_i - 1
        a2 = a[1].to_i - 1
        path[a1] << a2
        path[a2] << a1
    end

    d = []
    dlist = []
    numOfVMs.times { dlist << {} }

    for i in 0...numOfVMs
        d << path[i].length
    end

    j = 11

    for node in 0...numOfVMs
        for k in 0...path[node].length
                if not dlist[node].include? path[node][k]
                        dlist[node][path[node][k]] = "10.#{subnet}.#{j}.1"
                        dlist[path[node][k]][node] = "10.#{subnet}.#{j}.2"
                end
                j += 1
        end
    end

    for node in 0...numOfVMs
        h[node].write(dlist[node].keys().length.to_s)
        i = 1

        for k in dlist[node].keys
                g[node].write("#{k+1} #{dlist[node][k]} eth#{i} \n")
                i += 1
        end
    end

    graph.close

    for i in 0...numOfVMs
        g[i].close
        h[i].close
    end

    logger.info "Making the private IP address is completed"

    f = File.open("./tmp/entire_path", "r")
    g = []
    h = []

    for i in 0...numOfVMs
        g << File.open("./tmp/vmIP.#{i+1}", "r")
        h << File.open("./tmp/vmRT.#{i+1}", "w")
    end

    rlist = [{}]
    plist = []
    iplist = [[]]

    for i in 0...numOfVMs
        rlist << {}
        iplist << []
    end

    for i in 0...numOfVMs
        p = {}

        for line in g[i]
                v = line.split(" ")
                n = v[0].to_i
                ip = v[1]
                iplist[i+1] << ip
                p[n] = v[2][0..-1]
        end

        plist << p
    end

    print "#{iplist}\n"
    print "#{plist}\n"

    for line in f
        v = line.split(" ")
        n = v[0].to_i
        d = v[2].to_i
        e = plist[(n-1)][v[1].to_i]

        for k in iplist[d]
                rlist[n][k] = e
        end
    end

    n = 0

    for hfile in h
        n = n + 1
        for j in rlist[n].keys
                hfile.write("#{j} #{rlist[n][j]}\n")
        end
    end

    f.close

    for i in 0...numOfVMs
        g[i].close
        h[i].close
    end

    logger.info "Making the Routing Table is completed"

  end

  work :get_ip do |res|
    logger.info "#{res.property.vm_name}'s ip address is #{res.property.manageIP}"
  end

  work :set_ip do |res|
#    time = res.property.node * 10
#    sleep(time)
#    sleep(3.0)
    try_ip = true

    while try_ip do
        cmd = "sudo cp /var/lib/dhcp/dhcpd.leases ./tmp/dhcpd.leases.#{res.property.sn}"
        res.execute_cmd(cmd, "Copying the leases list to get the management ip", "Failed", "Copying is completed")

        f = File.open("./tmp/dhcpd.leases.#{res.property.sn}", "r")
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

        sleep(1.0)
    end

    g = File.open("./tmp/nodeIPs", "a")
    addr = candidate[-1].split(" ")[1]
    res.property.manageIP = addr

    g.write("#{res.property.sn} #{res.property.manageIP}\n")
    g.close

    logger.info "#{res.property.vm_name}'s ip address is set to #{res.property.manageIP}"
  end

  work :get_name do |res|
    logger.info "the resource name is #{res.property.vm_name}"
  end

  work :ping_gw do |res|
    f = File.open("./#{res.property.id}_result.log", "a")
    f.write("ping to the gateway 3 times from #{res.property.sn} (#{res.property.vm_name})\n")
    f.close

    sleep(2.0)

    `sshpass -p test scp -r ./#{res.property.id}_result.log root@#{res.property.manageIP}:~/`
    `sudo mv ./#{res.property.id}_result.log #{res.property.id}_result.log.bak`
    pwd = `pwd`[0...-1]

    cmd = "sshpass -p test #{SSH} -X -f -o StrictHostKeyChecking=no root@#{res.property.manageIP} \"echo \'before ping\' >> #{res.property.id}_result.log;echo \"`date +%s%N` ns\" >> #{res.property.id}_result.log;ping -c 3 172.16.11.1;echo \'after ping\' >> #{res.property.id}_result.log;echo \"`date +%s%N` ns\" >> #{res.property.id}_result.log;sshpass -p #{res.property.password} scp -r #{res.property.id}_result.log #{res.property.id}@#{res.property.ip}:#{pwd}/#{res.property.id}_result.log\""
    res.execute_cmd(cmd, "Ping to the gateway", "Failed", "Ping success!")
  end

  work :ccn_get_file do |res|
    f = File.open("./#{res.property.id}_result.log", "a")
    f.write("request #{res.property.target_file} from #{res.property.sn} (#{res.property.vm_name})\n")
    f.close

    sleep(2.0)

    `sshpass -p test scp -r #{res.property.id}_result.log root@#{res.property.manageIP}:~/`
    `sudo mv ./#{res.property.id}_result.log #{res.property.id}_result.log.bak`
    pwd = `pwd`[0...-1]
    
    cmd = "sshpass -p test #{SSH} -X -f -o StrictHostKeyChecking=no root@#{res.property.manageIP} \"export PATH=$PATH:/usr/java/jdk1.7.0_07/bin:/usr/local/apache-ant-1.9.4/bin;source /etc/profile;echo \'before ccn get\' >> #{res.property.id}_result.log; echo \"`date +%s%N` ns\" >> #{res.property.id}_result.log;ccngetfile -v -unversioned #{res.property.target_file} #{res.property.output_file};echo \'after ccn get\' >> #{res.property.id}_result.log; echo \"`date +%s%N` ns\" >> #{res.property.id}_result.log;sshpass -p #{res.property.password} scp -r #{res.property.id}_result.log #{res.property.id}@#{res.property.ip}:#{pwd}/#{res.property.id}_result.log\""
    res.execute_cmd(cmd, "Getting the file #{res.property.target_file}", "Failed", "ccnget success!")
  end

  work :ccn_get_ip do |res|
    f = File.open("./#{res.property.id}_result.log", "a")
    f.write("request #{res.property.target_file} and send back to IP network from #{res.property.sn} (#{res.property.vm_name})\n")
    f.close

    sleep(2.0)

    `sshpass -p test scp -r ./#{res.property.id}_result.log root@#{res.property.manageIP}:~/`
    `sudo mv ./#{res.property.id}_result.log #{res.property.id}_result.log.bak`
    pwd = `pwd`[0...-1]
    
    cmd = "sshpass -p test #{SSH} -X -f -o StrictHostKeyChecking=no root@#{res.property.manageIP} \"export PATH=$PATH:/usr/java/jdk1.7.0_07/bin:/usr/local/apache-ant-1.9.4/bin;source /etc/profile;echo \'before ccn get\' >> #{res.property.id}_result.log; echo \"`date +%s%N` ns\" >> #{res.property.id}_result.log;ccngetfile -v -unversioned #{res.property.target_file} #{res.property.output_file};echo \'after ccn get\' >> #{res.property.id}_result.log; echo \"`date +%s%N` ns\" >> #{res.property.id}_result.log;\""
    res.execute_cmd(cmd, "Getting the file #{res.property.target_file}", "Failed", "ccnget success! now it will be sent back")
    cmd = "sshpass -p test #{SSH} -X -f -o StrictHostKeyChecking=no root@#{res.property.manageIP} \"echo \'before send the output file to IP network\' >> #{res.property.id}_result.log; echo \'`date +%s%N` ns\' >> #{res.property.id}_result.log; sshpass -p #{res.property.back_password} scp -r #{res.property.output_file} #{res.property.back_id}@#{res.property.back}:~/#{res.property.output_file}; echo \'after send the output file to IP network\' >> #{res.property.id}_result.log; echo \'`date +%s%N` ns\' >> #{res.property.id}_result.log;sshpass -p #{res.property.password} scp -r #{res.property.id}_result.log #{res.property.id}@#{res.property.ip}:#{pwd}/#{res.property.id}_result.log\""
    res.execute_cmd(cmd, "Sending the file to #{res.property.back}", "Failed", "Sending success!")
  end

  work :ccn_put_file do |res|
    f = File.open("./#{res.property.id}_result.log", "a")
    f.write("put #{res.property.put_file} into ccnx:/#{res.property.repoName} from #{res.property.sn} (#{res.property.vm_name})\n")
    f.close

    sleep(2.0)

    `sshpass -p test scp ./#{res.property.id}_result.log root@#{res.property.manageIP}:~/`
    `sudo mv ./#{res.property.id}_result.log #{res.property.id}_result.log.bak`
    pwd = `pwd`[0...-1]
    cmd = "sshpass -p test #{SSH} -X -f -o StrictHostKeyChecking=no root@#{res.property.manageIP} \"export PATH=$PATH:/usr/java/jdk1.7.0_07/bin:/usr/local/apache-ant-1.9.4/bin;source /etc/profile;echo \'before ccn put\' >> #{res.property.id}_result.log; echo \"`date +%s%N` ns\" >> #{res.property.id}_result.log;cd ~;ccnputfile -v -unversioned ccnx:/#{res.property.repoName}/#{res.property.put_file} ~/#{res.property.put_file}; echo \'after ccn put\' >> #{res.property.id}_result.log; echo \"`date +%s%N` ns\" >> #{res.property.id}_result.log;sshpass -p #{res.property.password} scp -r #{res.property.id}_result.log #{res.property.id}@#{res.property.ip}:#{pwd}/\""
    res.execute_cmd(cmd, "Putting the file to ccnx:/#{res.property.repoName}/#{res.property.put_file}", "Failed", "ccnput success!")
  end

  work :video_streaming do |res|
    cmd = "sshpass -p test #{SSH} -X -f -o StrictHostKeyChecking=no root@#{res.property.manageIP} \"vlc #{res.property.video}\""
    res.execute_cmd(cmd, "Video Streaming Start!", "Failed", "Video Streaming Success!")
  end

  work :ping_to_vm do |res|
    file = File.new("./tmp/nodeIPs")
    n = res.property.target
    f = File.open("./#{res.property.id}_result.log", "a")
    f.write("ping from #{res.property.sn} (#{res.property.vm_name}) to #{res.property.target}\n")
    f.close

    sleep(2.0)

    `sshpass -p test scp ./#{res.property.id}_result.log root@#{res.property.manageIP}:~/`
    `sudo mv ./#{res.property.id}_result.log #{res.property.id}_result.log.bak`
    pwd = `pwd`[0...-1]
 
    for line in file
      if line.split(" ")[0].include? n.to_s
        break
      end
    end

    list = line.split(" ")

    cmd = "sshpass -p test #{SSH} -X -f -o StrictHostKeyChecking=no root@#{res.property.manageIP} \"echo \'before ping\' >> #{res.property.id}_result.log; echo \"`date +%s%N` ns\" >> #{res.property.id}_result.log;ping -c 3 #{list[1]}; echo \'after ping\' >> #{res.property.id}_result.log; echo \"`date +%s%N` ns\" >> #{res.property.id}_result.log;sshpass -p #{res.property.password} scp -r #{res.property.id}_result.log #{res.property.id}@#{res.property.ip}:#{pwd}/#{res.property.id}_result.log\""
    res.execute_cmd(cmd, "Ping from #{res.property.sn} to #{res.property.target}", "Failed", "ping success!")
  end

  work :making_xml do |res|
    inputlines = ["    <interface type=\'network\'>", "      <source network=\'ovsbr1\'/>", "      <model type=\'virtio\'/>", "    </interface>"]
    f = File.open("./tmp/port.#{res.property.sn}", "r")
    n = f.gets.to_i
    cmd = "sudo cp /etc/libvirt/qemu/#{res.property.vm_name}.xml ./tmp/tmp_#{res.property.vm_name}.xml"
    res.execute_cmd(cmd, "Copy the xml file to tmp directory", "Failed", "Copy success!")
    old_xml = open("./tmp/tmp_#{res.property.vm_name}.xml", "r")
    new_xml = open("./tmp/#{res.property.vm_name}.xml", "w")

    mac = ""

    for line in old_xml
      if line.include? 'mac address'
        mac = line.split("=")[1][1..-5]
        new_xml.write(line)
        break
      else
        new_xml.write(line)
      end
    end

    for line in old_xml
      if line.include? '/inter'
        new_xml.write(line)
        break
      else
        new_xml.write(line)
      end
    end

    n.times {
      for line in inputlines
        new_xml.write("#{line}\n")
      end
    }

    for line in old_xml
      new_xml.write(line)
    end

    old_xml.close
    new_xml.close
    
    res.property.macAddress = mac
    logger.info "#{res.property.vm_name}'s mac address is #{res.property.macAddress}"

    cmd = "sudo /usr/bin/virsh -c #{res.property.hypervisor_uri} define ./tmp/#{res.property.vm_name}.xml"
    res.execute_cmd(cmd, "Define the new xml file", "Failed", "Define success!")
    sleep(5)
  end

  work :set_eth do |res|
    lst = res.property.vmIP

    cmds ||=[]
    cmds << "\""

    lst.each do |line|
      v = line.split
      c = "ifconfig #{v[2]} #{v[1]} netmask 255.255.255.0;"
      cmds << c
    end

    cmds << "\""

    cmd = "sshpass -p test #{SSH} -f -o StrictHostKeyChecking=no root@#{res.property.manageIP} "
    cmds.each do |c|
      cmd << c
    end

    success = false

    while !success do
        success = res.execute_cmd(cmd, "Setting the ip address with " + cmd, "Failed", "Set vm ip success!")
    end

  end

  work :making_ccn_table do |res|
    num = res.property.node
    h = File.open("./tmp/entire_path", "r")
    ip = []

    for i in 1..num
      ip << File.open("./tmp/vmIP.#{i}")
    end

    rlist = [{}]
    iplist = [{}]

    for i in 0...num
      rlist << {}
      iplist << {}
    end

    fnum = 0

    for f in ip
      fnum = fnum + 1
      for line in f
        v = line.split(" ")
        hop = v[0].to_i
        i = v[1]
        iplist[fnum][hop] = i
      end
    end

    for f in ip
      f.close
    end

    for line in h
      v = line.split(" ")
      n = v[0].to_i
      hop = v[1].to_i
      d = v[2].to_i
      rlist[n][d] = iplist[hop][n]
    end

    h.close

    case res.property.role
    when "publisher"
      f = File.open("./tmp/ccnd.conf.#{res.property.sn}", "w")
      f.close
    else
      f = File.open("./tmp/ccnd.conf.#{res.property.sn}", "w")

#TODO
      for k in [1]
        f.write("add ccnx:/snu.ac.kr udp #{rlist[res.property.sn][k]}\n")
        f.write("add ccnx:/ccnx.org udp #{rlist[res.property.sn][k]}\n")
        f.write("add ccnx:/ udp #{rlist[res.property.sn][k]}\n")
        f.write("add ccnx:/snu.ac.kr tcp #{rlist[res.property.sn][k]}\n")
        f.write("add ccnx:/ccnx.org tcp #{rlist[res.property.sn][k]}\n")
        f.write("add ccnx:/ tcp #{rlist[res.property.sn][k]}\n")

      end

      f.close
    end
#TODO
  end

  work :set_ccn do |res|
    cmd = "sshpass -p test scp -r ./tmp/ccnd.conf.#{res.property.sn} root@#{res.property.manageIP}:/root/.ccnx/ccnd.conf"
    res.execute_cmd(cmd, "Setting the ccn configuration file with " + cmd, "Failed", "#{res.property.vm_name}: Set ccn configuration file success!")

    success = false

    case res.property.role
    when "publisher"
      cmd = "sshpass -p test ssh -X -f -o StrictHostKeyChecking=no root@#{res.property.manageIP} \"nohup ccndstart > foo.out 2> foo.err < /dev/null &\""
      while !success do
          success = res.execute_cmd(cmd, "Starting the ccn daemon with #{cmd}", "Failed to start daemon", "#{res.property.vm_name}: Starting the ccn daemon success!")
      end
      #cmd = "sshpass -p test ssh -f -o StrictHostKeyChecking=no root@#{res.property.manageIP} \"export PATH=$PATH:/usr/java/jdk1.7.0_07/bin:/usr/local/apache-ant-1.9.4/bin;source /etc/profile;ccn_repo #{res.property.repoName} > repo.out 2> repo.err < /dev/null &\""

      # TODO: delete mkdir : need to revise it.

      cmd = "sshpass -p test ssh -X -f -o StrictHostKeyChecking=no root@#{res.property.manageIP} \"export PATH=$PATH:/usr/java/jdk1.7.0_07/bin:/usr/local/apache-ant-1.9.4/bin;source /etc/profile;cd #{res.property.repoName};export CCNR_DIRECTORY=\`pwd\`;nohup ccnr > foo.out 2> foo.err < /dev/null &\""
      success = false
      while !success do 
          success = res.execute_cmd(cmd, "Making the repository with #{cmd}", "Failed to start the repository", "#{res.property.vm_name}: Making the repository with the prefix ccnx:/#{res.property.repoName}")
      end
    else
      cmd = "sshpass -p test ssh -X -f -o StrictHostKeyChecking=no root@#{res.property.manageIP} \"nohup ccndstart > foo.out 2> foo.err < /dev/null &\""
      while !success do
          success = res.execute_cmd(cmd, "Starting the ccn daemon with #{cmd}", "Failed to start daemon", "#{res.property.vm_name}: Starting the ccn daemon success!")
      end
    end

    logger.info "#{res.property.role} is preparing to start ccn networking"
  end

  work :set_rt do |res|
    lst = res.property.vmRT

    cmds ||=[]
    cmds << "\""

    lst.each do |line|
      v = line.split
      c = "route add #{v[0]} #{v[1]};"
      cmds << c
    end

    cmds << "\""

    cmd = "sshpass -p test #{SSH} -f -o StrictHostKeyChecking=no root@#{res.property.manageIP} "
    cmds.each do |c|
      cmd << c
    end

    success = false

    while !success do
        success = res.execute_cmd(cmd, "Setting the routing table with " + cmd, "Failed", "Set vm rt success!")
    end
  end
end
