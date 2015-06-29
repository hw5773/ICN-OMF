import libvirt
import os
import sys
import string
import time

if len(sys.argv) is 1:
	print "error!"
	sys.exit(0)

i = string.atoi(sys.argv[1]) + 1

for n in range(1, i):
	os.system('sudo virt-clone --original new --name vm'+str(n)+' --file /home/dhkim/vmtest/vmgenerator/vm'+str(n)+'.img')

inputlines = ["    <interface type=\'network\'>\n", "      <source network=\'ovsbr1\'/>\n", '      <model type=\'virtio\'/>\n', '    </interface>\n']

p = open("/home/dhkim/vmtest/vmgenerator/ports", "r")
d = {}

line = p.readline()

# to know the number of ports in each vms
while line: 
	v = line.split(" ")
	k = string.atoi(v[0])
	n = string.atoi(v[1][:-1])
	d[k] = n
	line = p.readline()


for n in range(1, i):
	os.system('sudo cp /etc/libvirt/qemu/vm'+str(n)+'.xml /home/dhkim/vmtest/vmgenerator/test'+str(n)+'.xml')
	f = open('/home/dhkim/vmtest/vmgenerator/test'+str(n)+'.xml', 'r')
	g = open('/home/dhkim/vmtest/vmgenerator/vm'+str(n)+'.xml', 'w')

	line = f.readline()
	index = line.find('ovsbr0')
	
	g.write(line)

	while index < 0:
		line = f.readline()
		index = line.find('ovsbr0')

		if index < 0:
			g.write(line)
		else:
			index2 = line.find('/inter')
			while index2 < 0:
				g.write(line)
				line = f.readline()
				index2 = line.find('/inter')
			index = 1

	g.write(line)	

	for k in range(d[n]):
		g.writelines(inputlines)

	while line:	
		t = line.find('user')
		while t > 0 :
			line = f.readline()
			t = line.find('/inter') * -1
		line = f.readline()
		t = line.find('user')
		if t < 0 :
			g.write(line)

	f.close()
	g.close()
	os.system('sudo cp /home/dhkim/vmtest/vmgenerator/vm'+str(n)+'.xml /etc/libvirt/qemu/vm'+str(n)+'.xml')

conn = libvirt.open('qemu:///system')

for n in range(1, i):
	g = open('/home/dhkim/vmtest/vmgenerator/vm'+str(n)+'.xml', 'r')
	xml = g.read()

	conn.defineXML(xml)

print "making " + str(i-1) + " nodes complete."

os.system('sudo rm /var/lib/dhcp/dhcpd.leases')
os.system('sudo touch /var/lib/dhcp/dhcpd.leases')
os.system('/etc/init.d/isc-dhcp-server restart')
	
for n in range(1, i):
	os.system('sudo virsh start vm'+str(n))
	os.system('sudo python /home/dhkim/vmtest/vmgenerator/getManageIP.py /var/lib/dhcp/dhcpd.leases ' + str(n))

p.close()
