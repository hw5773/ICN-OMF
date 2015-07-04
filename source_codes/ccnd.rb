num = 3
p = 1
r = 1
s = 1
h = File.open("./tmp/entire_path", "r")
ip = []

for i in 1..num
	ip << File.open("./tmp/vmIP.#{i}")
end

rlist = [{}]
iplist = [{}]

for i in 0...num
	rlist << {}
	iplist << {}
end

fnum = 0

for f in ip
	fnum = fnum + 1
	for line in f
		v = line.split(" ")
		hop = v[0].to_i
		i = v[1]
		iplist[fnum][hop] = i
	end
end

for f in ip
	f.close
end

for line in h
	v = line.split(" ")
	n = v[0].to_i
	hop = v[1].to_i
	d = v[2].to_i
	rlist[n][d] = iplist[hop][n]
end

h.close

n = 1

while n <= p
	f = File.open("./tmp/ccnd.conf.#{n}", "w")
	f.close
	n = n + 1
end

n = p + 1

while n <= p + r
	f = File.open("./tmp/ccnd.conf.#{n}", "w")

	for k in 1..p
		f.write("add ccnx:/snu.ac.kr udp #{rlist[n][k]}\n")
		f.write("add ccnx:/ccnx.org udp #{rlist[n][k]}\n")
		f.write("add ccnx:/ udp #{rlist[n][k]}\n")
	end

	f.close
	n = n + 1
end

n = p + r + 1

while n <= p + r + s
	f = open("./tmp/ccnd.conf.#{n}", "w")

	for k in 1..p
		f.write("add ccnx:/snu.ac.kr udp #{rlist[n][k]}\n")
		f.write("add ccnx:/ccnx.org udp #{rlist[n][k]}\n")
		f.write("add ccnx:/ udp #{rlist[n][k]}\n")
	end

	f.close
	n = n + 1
end

print rlist
