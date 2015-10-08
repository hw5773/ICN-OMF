Dir.mkdir ("tmp") unless File.exists? "tmp"
g = File.open("./graph.txt", "r")
h = File.open("./tmp/role", "w")
info  = File.open("./tmp/info", "w")

for line in g
	if line.include? "*/"
		break
	end
end

graph = {}
source = ""

n = 0
e = 0

for line in g
	if line.include? "pub" or line.include? "rt" or line.include? "sub"
		lst = line.split("\t")
		n = n + 1
		h.write("#{lst[1]} #{lst[0]}\n")
		if lst[0] == "pub"
			source = lst[1]
		else
			source = lst[1][0...-1]
		end
		graph[source] = {}
		next
	elsif line.include? "-"
	else
		lst = line.split("\t")
		e = e + 1
		if graph.keys.length == 0
			graph[source][lst[0]] = lst[1][0...-1]
		elsif graph[lst[0]].nil?
			graph[source][lst[0]] = lst[1][0...-1]
		end
	end
end

info.write("#{n} #{e/2}")

out = File.open("./tmp/graph", "w")

for a in graph.keys
	for b in graph[a].keys
		out.write("#{a} #{b} #{graph[a][b]}\n")
	end
end

g.close
h.close
out.close
