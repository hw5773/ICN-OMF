require './ICN_api'

def_property('vmgen', 'vmgen', 'Name of vmgen')
def_property('gwgen', 'gwgen', 'Name of gwgen')

defGroup('init', 'mbox1@mbox1')
defGroup('request', 'mbox2@mbox1')
defGroup('vmgens', prop.vmgen)

onEvent :ALL_UP do

	group('vmgens') do |g|
		ccn_setting(g, ARGV)
		onEvent :vm_set do
			info "Testing the CCN networking"
			pingGW(g, 1)
			pingGW(g, 2)
			pingGW(g, 3)

			after 5 do
				ccnput(g, 1)
			end

			after 10 do
				ccngetip(g, 2, "147.46.216.250")
			end

			after 30 do
				ccnget(g, 3)
					ccnget(g, 3)
			end

			after 40 do
				ccngetipgw(group('gwgens'), 0, "147.46.216.250")
			end

			after 60 do
				done!
			end
		end
	end
end
