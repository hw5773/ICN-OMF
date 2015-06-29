import sys
import string

f = open(sys.argv[1],'r')
g = open('/home/dhkim/vmtest/vmgenerator/nodeIPs', 'a')

line = f.readline()
index = line.find('172')
n = string.atoi(sys.argv[2])

while n > 0:
	line = f.readline()
	index = line.find('172')
	if index > 0:
		n = n - 1

ip = line.split(" ")

g.write(sys.argv[2] + " " + ip[1] + "\n")
print "vm" + sys.argv[2] + "\'s management ip : " + ip[1]

f.close()
g.close()
