Dir.mkdir ('tmp') unless File.exists? 'tmp'
graph = File.open("./graph", "r")

numOfVMs = ARGV[0].to_i
subnet = ARGV[1].to_i

g = []
h = [] 

for i in 1..numOfVMs
	g << File.open("./tmp/vmIP.#{i}", "w")
	h << File.open("./tmp/port.#{i}", "w")
end

n = graph.gets[0..-2].to_i
path = []
numOfVMs.times { path << [] }

for line in graph
	a = line.split(" ")
	a1 = a[0].to_i - 1
	a2 = a[1].to_i - 1
	path[a1] << a2
	path[a2] << a1
end

d = []
dlist = []
numOfVMs.times { dlist << {} }

for i in 0...numOfVMs
	d << path[i].length
end

j = 11

for node in 0...numOfVMs
	for k in 0...path[node].length
		if not dlist[node].include? path[node][k]
			dlist[node][path[node][k]] = "10.#{subnet}.#{j}.1"
			dlist[path[node][k]][node] = "10.#{subnet}.#{j}.2"
		end
		j += 1
	end
end

for node in 0...numOfVMs 
	h[node].write(dlist[node].keys().length.to_s)
	i = 1

	for k in dlist[node].keys
		g[node].write("#{k+1} #{dlist[node][k]} eth#{i} \n")
		i += 1
	end
end

graph.close

for i in 0...numOfVMs
	g[i].close
	h[i].close
end
