import sys
import string
import os

p = string.atoi(sys.argv[1])
r = string.atoi(sys.argv[2])
s = string.atoi(sys.argv[3])
num = p + r + s

# m for manage IPs
h = open("./source_codes/entire_path", "r")
ip = []

for i in range(num):
	ip.append(open("./source_codes/vmIP."+str(i+1)))

rlist = [{}] # for routing information
iplist = [{}]

for i in range(num):
	rlist.append({})
	iplist.append({})

fnum = 0
for f in ip:
	fnum = fnum + 1
	for line in f:
		v = line.split(" ")
		hop = string.atoi(v[0])
		i = v[1]
		iplist[fnum][hop] = i

for f in ip:
	f.close()

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
	f = open("./source_codes/ccnd.conf." + str(n), "w")
	f.close()
	n = n + 1

# for router

n = p + 1

while n <= p + r :
	f = open("./source_codes/ccnd.conf." + str(n), "w")
	
	for k in range(1, p+1):
#		f.write("add ccnx:/" + str(k) + " udp " + rlist[n][k] + "\n")
		f.write("add ccnx:/snu.ac.kr udp " + rlist[n][k] + "\n")
		f.write("add ccnx:/ccnx.org udp " + rlist[n][k] + "\n")

	f.close()
	n = n + 1

# for subscriber

n = p + r + 1

while n <= p + r + s :
	f = open("./source_codes/ccnd.conf." + str(n), "w")

	for k in range(1, p+1):
#		f.write("add ccnx:/" + str(k) + " udp " + rlist[n][k] + "\n")
		f.write("add ccnx:/snu.ac.kr udp " + rlist[n][k] + "\n")
		f.write("add ccnx:/ccnx.org udp " + rlist[n][k] + "\n")

	f.close()
	n = n + 1

