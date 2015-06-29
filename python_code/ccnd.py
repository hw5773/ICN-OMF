import sys
import string
import os

p = string.atoi(sys.argv[1])
r = string.atoi(sys.argv[2])
s = string.atoi(sys.argv[3])
num = p + r + s

# m for manage IPs
m = [0]
g = open("./nodeIPs", "r")
h = open("./routing_table.txt", "r")
ip = open("./vmIPs", "r")

rlist = [{}] # for routing information
iplist = [{}]

for i in range(num):
	rlist.append({})
	iplist.append({})

# making ip list for each NIC in vms
line = ip.readline()

while line:
	if len(line)<=2:
		node = string.atoi(line[:-1])
	else:
		v = line.split(" ")
		hop = string.atoi(v[0]) # the next hop
		i = v[1] # ip address of the next hop
		iplist[node][hop] = i
	line = ip.readline()

ip.close()

line = g.readline()

while line:
	v = line.split(" ")
	m.append(v[1][:-1])
	line = g.readline()

g.close()

# making routing path information with ip address
line = h.readline()

while line:
	v = line.split(" ")
	n = string.atoi(v[0]) # this node number
	hop = string.atoi(v[1]) # the next hop
	d = string.atoi(v[2]) # the destination node number
	rlist[n][d] = iplist[hop][n]
	
	line = h.readline()


h.close()

# for publisher

n = 1

while n <= p :
	f = open("/home/dhkim/vmtest/vmgenerator/ccnd.conf." + str(n), "w")
	f.close()
	n = n + 1

# for router

n = p + 1

while n <= p + r :
	f = open("/home/dhkim/vmtest/vmgenerator/ccnd.conf." + str(n), "w")
	
	for k in range(1, p+1):
#		f.write("add ccnx:/" + str(k) + " udp " + rlist[n][k] + "\n")
		f.write("add ccnx:/snu.ac.kr udp " + rlist[n][k] + "\n")
		f.write("add ccnx:/ccnx.org udp " + rlist[n][k] + "\n")

	f.close()
	n = n + 1

# for subscriber

n = p + r + 1

while n <= p + r + s :
	f = open("/home/dhkim/vmtest/vmgenerator/ccnd.conf." + str(n), "w")

	for k in range(1, p+1):
#		f.write("add ccnx:/" + str(k) + " udp " + rlist[n][k] + "\n")
		f.write("add ccnx:/snu.ac.kr udp " + rlist[n][k] + "\n")
		f.write("add ccnx:/ccnx.org udp " + rlist[n][k] + "\n")

	f.close()
	n = n + 1

