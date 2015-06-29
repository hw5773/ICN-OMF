defGroup('init', 'mbox2@mbox1')

onEvent :ALL_UP do
	group("init").exec("hostname")
	group("init").exec("pwd")
	group("init").exec("sudo cat source_codes/vmname")
#	done!
end
