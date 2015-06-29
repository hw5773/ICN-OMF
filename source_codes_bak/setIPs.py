import os
import string
import time

f = open("./source_codes/nodeIPs", 'r')
g = open("./source_codes/vmIPs", 'r')

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
cmd  = {}

while line:
	if len(line)<=2:
		node = string.atoi(line)
		line = g.readline()
		i = 0
		cmd[str(node)] = ""
	else:
		v = line.split(" ")
		ip = v[1]
		i = i + 1
		print "setting ip to eth" + str(i) + " of vm" + str(node) + " : " + ip
		cmd[str(node)] = cmd[str(node)] + " sudo ifconfig eth" + str(i) + " " + ip + " netmask 255.255.255.0;"
	#	os.system("sshpass -p test ssh -t -o StrictHostKeyChecking=no root@" + d[str(node)] + " sudo ifconfig eth" + str(i) + " " + ip + " netmask 255.255.255.0")
		print "setting ip to eth" + str(i) + " of vm" + str(node) + " : " + ip + " complete!"
		line = g.readline()

for n in cmd.keys():
	os.system("sshpass -p test ssh -t -T -o StrictHostKeyChecking=no root@" + d[n] + " \"" + cmd[n] + "\"")

f.close()
g.close()
