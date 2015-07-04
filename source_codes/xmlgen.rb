inputlines = ["    <interface type=\'network\'>", "      <source network=\'ovsbr1\'/>", "      <model type=\'virtio\'/>", "    </interface>"]
    f = File.open("./tmp/port.1", "r")
    n = f.gets.to_i
    `sudo cp /etc/libvirt/qemu/user_11436013371.xml ./tmp/tmp_user_11436013371.xml`
    old_xml = open("./tmp/tmp_user_11436013371.xml", "r")
    new_xml = open("./tmp/user_11436013371.xml", "w")

    mac = ""

    for line in old_xml
      if line.include? 'mac address'
        mac = line
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

    lst = mac.split("=")
    addr = lst[1][1..-5]

    print addr
