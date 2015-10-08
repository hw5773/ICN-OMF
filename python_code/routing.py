import string
import sys

f = open("./source_codes/entire_path", "r")

num = int(sys.argv[1])
g = []
h = []

for i in range(num):
	g.append(open("./source_codes/vmIP."+str(i+1), "r"))
	h.append(open("./source_codes/vmRT."+str(i+1), "w"))

# routing information
rlist = [{}]

# port information
plist = []

#ip list of vms
iplist = [[]]

for i in range(num):
	rlist.append({})
	iplist.append([])
i = 0

# iplist for each ports of vms
for i in range(num):
	p = {}
	line = g[i].readline()
	while line:
		v = line.split(" ")
		n = int(v[0])
		ip = v[1]
		iplist[i+1].append(ip)
		p[n] = v[2][:-1]
		line = g[i].readline()
	plist.append(p)

line = f.readline()

# making routing table for each ports in vms
while line:
	v = line.split(" ")
	n = int(v[0])
	d = int(v[2])
	e = plist[(n-1)][int(v[1])]
	
	for k in iplist[d]:
		rlist[n][k] = e

	line = f.readline()

# writing for file vmRTs
n = 0
for hfile in h:
	n = n + 1
	for j in rlist[n].keys():
		hfile.write(j + " " + rlist[n][j] + "\n")

f.close()

for i in range(num):
	g[i].close()
	h[i].close()
