import string
import sys

f = open("/home/dhkim/vmtest/vmgenerator/routing_table.txt", "r")
g = open("/home/dhkim/vmtest/vmgenerator/vmIPs", "r")
h = open("/home/dhkim/vmtest/vmgenerator/vmRTs", "w")

num = string.atoi(sys.argv[1])

# routing information
rlist = [{}]

# port information
p = {}
plist = []

#ip list of vms
iplist = [[]]

for i in range(num):
	rlist.append({})
	iplist.append([])

line = g.readline()

i = 0

# iplist for each ports of vms
while line:
	if len(line)<=2 :
		plist.append(p)
		p = {}
		node = string.atoi(line[:-1])
		line = g.readline()
		i = i + 1
	else:
		v = line.split(" ")
		n = string.atoi(v[0])
		ip = v[1]
		iplist[i].append(ip)
		e = v[2][:-1]
		p[n] = e
		line = g.readline()

plist.append(p)
line = f.readline()

# making routing table for each ports in vms
while line:
	v = line.split(" ")
	n = string.atoi(v[0])
	d = string.atoi(v[2])
	e = plist[n][string.atoi(v[1])]
	
	for k in iplist[d]:
		rlist[n][k] = e

	line = f.readline()

# writing for file vmRTs
for i in range(1, num+1):
	h.write(str(i) + "\n")

	for j in rlist[i].keys():
		h.write(j + " " + rlist[i][j] + "\n")

f.close()
g.close()
h.close()
