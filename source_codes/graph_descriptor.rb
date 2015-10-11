module OmfRc::Util::GraphDescriptor
  include OmfRc::ResourceProxyDSL

  work :making_random_graph do |res|
    Dir.mkdir('tmp') unless File.exists? 'tmp'

    r = File.open("./#{res.property.id}_result.log", "w")
    r.write("This is the log file for the result data.\nThe graph is a random graph\n")
    r.close
    cmd = "./graph.sh #{res.property.node} #{res.property.edge}"
    res.execute_cmd(cmd, "Generating the random graph with #{res.property.node} #{res.property.edge}", "Failed to generate the random graph", "Making the random graph success!")
  end

  work :making_description do |res|
    Dir.mkdir('tmp') unless File.exists? 'tmp'

    r = File.open("./#{res.property.id}_result.log", "w")
    r.write("This is the log file for the result data.\nThe graph is based on the graph.txt\n")
    r.close

    r.mkdir ("tmp") unless File.exists? "tmp"
    g = File.open("./graph.txt", "r")
    h = File.open("./tmp/role", "w")

    for line in g
        if line.include? "*/"
                break
        end
    end

    graph = {}
    source = ""

    for line in g
        if line.include? "pub" or line.include? "rt" or line.include? "sub"
                lst = line.split("\t")
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
                if graph.keys.length == 0
                        graph[source][lst[0]] = lst[1][0...-1]
                elsif graph[lst[0]].nil?
                        graph[source][lst[0]] = lst[1][0...-1]
                end
        end
    end

    out = File.open("./tmp/graph", "w")
    out.write("#{res.property.edge/2}\n")

    for a in graph.keys
        for b in graph[a].keys
                out.write("#{a} #{b} #{graph[a][b]}\n")
        end
    end

    g.close
    h.close
    out.close

	sleep(2.0)
	cmd = "sudo ./path_search #{res.property.node} #{res.property.edge/2}"
	  res.execute_cmd(cmd, "Making the graph based on Graph Descriptor", "Failed", "Making the graph success!")
  # entire_path arguments 
  # graph file checking - first line
  end
end
