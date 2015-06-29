import os
import sys
import string
from random import randrange

f = open("/home/dhkim/vmtest/vmgenerator/nodeIPs", 'r')

p = string.atoi(sys.argv[1]) # the number of the publisher
r = string.atoi(sys.argv[2]) # the number of the router
s = string.atoi(sys.argv[3]) # the number of the subscriber

d = {}
line = f.readline()

while line:
	v = line.split(" ")
	k = v[0]
	ip = v[1][:-1]
	d[k] = ip
	line = f.readline()

print "\nNow, ccn testing with ccngetfile"

for i in range(5):
	randP = randrange(p)+1
	randS = randrange(s)+p+r+1
	print "\nTest #" + str(i+1) + "----------"
#	print "The subscriber #" + str(randS) + " requests to get file ccnx:/" + str(randP) + "/test"
	print "The subscriber #" + str(randS) + " requests to get file ccnx:/snu.ac.kr/test"
	print "Access to the subscriber #" + str(randS) + " and open the file\n"
	os.system("sshpass -p test ssh -o StrictHostKeyChecking=no root@" + d[str(randS)] + " \"export PATH=$PATH:/usr/java/jdk1.7.0_07/bin:/usr/local/apache-ant-1.9.4/bin;source /etc/profile;ccngetfile ccnx:/snu.ac.kr/test testfile;cat testfile\"")
	print "\n--------------------------"

f.close()
