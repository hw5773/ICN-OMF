gfile = File.new("graph.txt", "r")
pfile1 = File.new("./tmp/repository_list", "w")
pfile2 = File.new("graph", "w")

line_counter = 0
node_counter = 0 
snode_id = "0"
dnode_id = "0"
repo_name = ""
edge_hash = Hash.new(0)
# node_couple = "" 

while (line = gfile.gets)
	line_counter += 1
		
	if line_counter > 6
		words = line.split("	")
				
		case words[0]
		when "-\n"
			node_counter += 1
			snode_id = "0"
			dnode_id = "0"
			repo_name = ""
		when "pub"
			snode_id = words[1]
			repo_name = words[2]
			pfile1.puts "#{snode_id} #{repo_name}" # file write to pfile1
		when "rt"
			snode_id = words[1].strip
		when "sub"
			snode_id = words[1].strip
		else
			dnode_id = words[0]
			weight = words[1]
			node_couple = ""
			node_couple << snode_id
			# puts "#{node_couple}: #{snode_id}"
			node_couple << " "
			node_couple << dnode_id
			# puts "#{node_couple}: #{snode_id}"
			edge_hash[node_couple] = weight
		end
	end
end
# file write to pfile2
pfile2.puts "#{node_counter}"
edge_hash.each do |nodes, weight|
	pfile2.puts "#{nodes} #{weight}" 
end

gfile.close
pfile1.close
pfile2.close
