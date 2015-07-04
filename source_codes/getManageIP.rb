f = File.open(ARGV[0], "r")
ip = []

for line in f
	if line.include? "172"
		ip << line
	end
end

n = line.length
addr = ip[n-1].split(" ")
print addr[1]

f.close
