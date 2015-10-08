module OmfRc::Util::GraphDescriptor
  include OmfRc::ResourceProxyDSL

  work :making_random do |res|
    Dir.mkdir('tmp') unless File.exists? 'tmp'
    user = `whoami`[0...-1]

    Dir.mkdir('result') unless File.exists? 'result'

    r = File.open("./result/#{res.property.id}_result.log", "w")
    r.write("This is the log file for the result data.")
    r.close
    cmd = "./graph.sh #{res.property.node} #{res.property.edge}"
    res.execute_cmd(cmd, "Generating the random graph with #{res.property.node} #{res.property.edge}", "Failed to generate the random graph", "Making the random graph success!")

    cmd = "sudo chown #{user} ./result; sudo chgrp #{user} ./result"
    res.execute_cmd(cmd, "Changing the permission on result", "Failed to change", "Changing the permission success!")
  end
end
