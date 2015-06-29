import os
import string

f = open("/home/dhkim/vmtest/vmgenerator/nodeIPs", 'r')
g = open("/home/dhkim/vmtest/vmgenerator/vmIPs", 'r')

d = {}

line = f.readline()

while line:
	v = line.split(" ")
	k = v[0]
	ip = v[1][:-1]
	d[k] = ip
	line = f.readline()

line = g.readline()
node = 0

while line:
	if len(line)<=2:
		node = string.atoi(line)
		line = g.readline()
		i = 0
	else:
		v = line.split(" ")
		ip = v[1]
		i = i + 1
		os.system("sshpass -p test ssh -o StrictHostKeyChecking=no root@" + d[str(node)] + " ifconfig eth" + str(i) + " " + ip + " netmask 255.255.255.0")
		print "setting ip to eth" + str(i) + " of vm" + str(node) + " : " + ip
		line = g.readline()

f.close()
g.close()
