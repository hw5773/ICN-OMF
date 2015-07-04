f = File.open("./entire_path", "r")

num = ARGV[0].to_i
g = []
h = []

for i in 0...num
	g << File.open("./tmp/vmIP.#{i+1}", "r")
	h << File.open("./tmp/vmRT.#{i+1}", "w")
end

rlist = [{}]
plist = []
iplist = [[]]

for i in 0...num
	rlist << {}
	iplist << []
end

for i in 0...num
	p = {}

	for line in g[i]
		v = line.split(" ")
		n = v[0].to_i
		ip = v[1]
		iplist[i+1] << ip
		p[n] = v[2][0..-1]
	end

	plist << p
end

print "#{iplist}\n"
print "#{plist}\n"

for line in f
	v = line.split(" ")
	n = v[0].to_i
	d = v[2].to_i
	e = plist[(n-1)][v[1].to_i]

	for k in iplist[d]
		rlist[n][k] = e
	end
end

n = 0

for hfile in h
	n = n + 1
	for j in rlist[n].keys
		hfile.write("#{j} #{rlist[n][j]}\n")
	end
end

f.close

for i in 0...num
	g[i].close
	h[i].close
end
