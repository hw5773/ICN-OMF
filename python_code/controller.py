import os
import sys
import string

# sys.argv[1] : the number of nodes

if len(sys.argv)<6 :
	print "more arguments are needed"
	print "<Usage> : python controller.py <# of nodes> <# of edges> <# of publisher> <# of router> <# or subscriber>"
	sys.exit(0)
elif len(sys.argv) > 6 :
	print "too many arguments"
	print "<Usage> : python controller.py <# of nodes> <# of edges> <# of publisher> <# of router> <# or subscriber>"
	sys.exit(0)

num = string.atoi(sys.argv[1])
p = string.atoi(sys.argv[3])
r = string.atoi(sys.argv[4])
s = string.atoi(sys.argv[5])

if num != (p + r + s) :
	print "<# of nodes> and the sum of <# of publisher>, <# of router>, and <# of subscriber> is mismatch."
	sys.exit(0)

# start generating
print "making random graph and making the entire path..."
os.system("sudo /home/dhkim/vmtest/vmgenerator/route_info.sh " + sys.argv[1] + " " + sys.argv[2])
print "path search is completed."
os.system("sudo python /home/dhkim/vmtest/vmgenerator/analysis.py")
print "analyzing the information to prepare for assigning the ip address."
print "start making the nodes"
os.system("sudo python /home/dhkim/vmtest/vmgenerator/vmgen.py " + sys.argv[1])
os.system("sudo python /home/dhkim/vmtest/vmgenerator/routing.py " + sys.argv[1])
print "making the routing table complete."
os.system("sudo python /home/dhkim/vmtest/vmgenerator/ccnd.py " + sys.argv[3] + " " + sys.argv[4] + " " + sys.argv[5])
print "making the ccn configuration file complete."
print "start setting the ip address to the eth ports of nodes"
os.system("sudo python /home/dhkim/vmtest/vmgenerator/setIPs.py")
print "ip address setting complete."
print "start setting the routing table for each nodes"
os.system("sudo python /home/dhkim/vmtest/vmgenerator/setRTs.py " + sys.argv[1])
print "routing table setting complete."
print "start setting the ccn configure files for each nodes"
os.system("sudo python /home/dhkim/vmtest/vmgenerator/setccnd.py " + sys.argv[3] + " " + sys.argv[4] + " " + sys.argv[5])
print "ccn configure files setting complete."
print "deleting the temporary files."
#os.system("sudo python /home/dhkim/vmtest/vmgenerator/delete.py")
print "the mission complete.\n"

print "------------report------------"
print sys.argv[1] + " nodes are made."

i=1
while i<(p+1):
	print "vm" + str(i) + " is the Publisher"
	i = i + 1

while i<(p+r+1):
	print "vm" + str(i) + " is the Router"
	i = i + 1

while i<(p+r+s+1): 
 	print "vm" + str(i) + " is the Subscriber"
	i = i + 1

print "------------------------------"

os.system("sudo python /home/dhkim/vmtest/vmgenerator/ccntest.py " + sys.argv[3] + " " + sys.argv[4] + " " + sys.argv[5])

