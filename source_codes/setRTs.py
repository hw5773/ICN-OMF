import sys
import string
import os

num = string.atoi(sys.argv[1]) # the number of nodes
f = open("./source_codes/vmRTs", "r")
g = open("./source_codes/nodeIPs", "r")

line = g.readline()

# making the list of manage IPs
m = [0]

while line:
	v = line.split(" ")
	m.append(v[1][:-1])
	line = g.readline()

line = f.readline()

while line:
	if len(line)<=2:
		n = string.atoi(line[:-1])
		print "start setting vm" + str(n) + "\'s routing table."
		line = f.readline()
	else:
		v = line.split(" ")
		os.system("sshpass -p test ssh -o StrictHostKeyChecking=no root@" + m[n] + " \"route add " + v[0] + " " + v[1][:-1] + "\"")
		print "route add " + v[0] + " " + v[1][:-1] + " by " + m[n] + "(vm" + str(n) + ")"
		line = f.readline()
		if len(line)<=2:
			print "setting vm" + str(n) + "\'s routing table complete."


f.close()
g.close()
