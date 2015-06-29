import string
import sys

f = open("./source_codes/graph", "r")

numOfVMs = int(sys.argv[1])
g = []
h = []

for i in range(numOfVMs):
	g.append(open("./source_codes/vmIP."+str(i+1), "w"))
	h.append(open("./source_codes/port."+str(i+1), "w"))

line = f.readline()
n = string.atoi(line)

path = [[] for row in range(n)]

line = f.readline()

# making edge table
while line:
	a = line.split(" ")
	a1 = string.atoi(a[0]) - 1
	a2 = string.atoi(a[1]) - 1
	path[a1].append(a2)
	path[a2].append(a1)
	line = f.readline()

# initializing for each information
d=[]
dlist=[]

for i in range(n):
	d.append(len(path[i]))

for i in range(n):
	dlist.append({})

# j is used for making network address.
j = 11

# set ips for each network
for node in range(numOfVMs):
	for k in range(len(path[node])):
		if not path[node][k] in dlist[node] :
			dlist[node][path[node][k]] = '10.0.'+str(j)+'.1'
			dlist[path[node][k]][node] = '10.0.'+str(j)+'.2'
		j = j + 1

# writing in the file vmIPs
for node in range(numOfVMs):
	i = 1
	h[node].write(str(len(dlist[node].keys())))

	for k in dlist[node].keys():
		g[node].write(str(k+1) + " " + dlist[node][k] + " eth" + str(i) +"\n")
		i = i + 1

f.close()

for i in range(numOfVMs):
	g[i].close()
	h[i].close()
