defProperty('res1', "unconfigured-node-1", "ID of a node")
defGroup('Actor', property.res1)

onEvent(:ALL_UP) do |event|
	after 3 do
		info "TEST - allGroups"
		allGroups.exec("/bin/uname -a")
	end

	after 6 do
		info "TEST - group"
		group("Actor").exec("/bin/hostname")
	end

	after 9 do
		Experiment.done
	end
end
