import os
import sys
import string
import pxssh

p = string.atoi(sys.argv[1])
r = string.atoi(sys.argv[2])
s = string.atoi(sys.argv[3])
secure = pxssh.pxssh()


f = open('./source_codes/nodeIPs', 'r')
line = f.readline()
d={}

while line:
	v = line.split(" ")
	k = v[0]
	d[k] = v[1][:-1]
	line = f.readline()

n = 1 

while n <= p :
	os.system("sudo sshpass -p test ssh -f -o StrictHostKeyChecking=no root@" + d[str(n)] + " \"ccndstart;export PATH=$PATH:/usr/java/jdk1.7.0_07/bin:/usr/local/apache-ant-1.9.4/bin;source /etc/profile;ccn_repo ccnx:/snu.ac.kr;ccnputfile ccnx:/snu.ac.kr/test /root/test.txt;\"")
	print "setting vm" + str(n) + "\'s ccnd.conf file complete."
	n = n + 1

n = p + 1

while n <= p + r :
	os.system("sudo sshpass -p test ssh -o StrictHostKeyChecking=no root@" + d[str(n)] + " \"export PATH=$PATH:/usr/java/jdk1.7.0_07/bin:/usr/local/apache-ant-1.9.4/bin;source /etc/profile\"")
	os.system("sudo sshpass -p test ssh -f -o StrictHostKeyChecking=no root@" + d[str(n)] + " \"ccndstart\"")
	print "setting vm" + str(n) + "\'s ccnd.conf file complete."
	n = n + 1

n = p + r + 1

while n <= p + r + s :
	os.system("sudo sshpass -p test ssh -o StrictHostKeyChecking=no root@" + d[str(n)] + " \"export PATH=$PATH:/usr/java/jdk1.7.0_07/bin:/usr/local/apache-ant-1.9.4/bin;source /etc/profile;\"")
	os.system("sudo sshpass -p test ssh -f -o StrictHostKeyChecking=no root@" + d[str(n)] + " \"ccndstart\"")
	print "setting vm" + str(n) + "\'s ccnd.conf file complete."
	n = n + 1

f.close()
