require './ICN_api'

defGroup('init', 'mbox1@mbox1')
defGroup('request', 'mbox2@mbox1')

onEvent :ALL_UP do
	group('init').exec("ls -l")
	group('request').exec("hostname")
end
