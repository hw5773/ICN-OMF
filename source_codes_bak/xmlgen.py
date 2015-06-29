import sys
import os
import string
import random
import libvirt

inputlines = ["    <interface type=\'network\'>\n", "      <source network=\'ovsbr1\'/>\n", '      <model type=\'virtio\'/>\n', '    </interface>\n']

p = []

i = int(sys.argv[1]) + 1

for j in range(i-1):
	p.append(open("./source_codes/port."+str(j+1), "r"))
d = {}
conn = libvirt.open('qemu:///system')

# to know the number of ports in each vms
for j in range(i-1):
	v = p[j].readline()
	n = int(v)
	d[j+1] = n

###

vmname = open('./source_codes/vmname', 'r')
vm = {}
for line in vmname:
	n = int(line[4:5])
	vm[n] = line[:-1]

for n in range(1, i):
	name = vm[n]
	os.system('sudo cp /etc/libvirt/qemu/'+name+'.xml ./source_codes/test'+name+'.xml')
	f = open('./source_codes/test'+name+'.xml', 'r')
	g = open('./source_codes/'+name+'.xml', 'w')

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
	os.system('sudo cp ./source_codes/'+name+'.xml /etc/libvirt/qemu/'+name+'.xml')

vmname.close()
vmname2 = open('./source_codes/vmname', 'r')

for n in range(1, i):
	name = vmname2.readline()[:-1]
	g = open('./source_codes/'+name+'.xml', 'r')
	xml = g.read()

	conn.defineXML(xml)
	print "define successfully"

vmname2.close()
