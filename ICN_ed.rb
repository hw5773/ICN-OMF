require './ICN_api'

if ARGV[-6].to_i > 0
	prefix = ARGV[-8]
	subnet = ARGV[-6].to_i
elsif ARGV[-2].to_i > 0
	prefix = ARGV[-4]
else
	prefix = ARGV[-2]
end

def_property('vmgen', 'vmgen', 'Name of vmgen')
def_property('gwgen', 'gwgen', 'Name of gwgen')

defGroup('init', 'mbox1@mbox1')
defGroup('requester', 'mbox2@mbox1')
defGroup("vmgens", prop.vmgen)
defGroup('gwgens', prop.gwgen)

onEvent :ALL_UP do
	subnet = ARGV[-6].to_i
	group('gwgens') do |g|
		gw_setting(g, "10.#{subnet}.12.100", "10.#{subnet}.12.2")
	end

	group("vmgens") do |g|
		ccn_setting(g, ARGV)
		onEvent :vm_ccn_set do
			info "Generating the CCN overlay network is completed."
			info "Testing the CCN networking"
			ping_gw(g, 1)
			ping_gw(g, 2)
			ping_gw(g, 3)

			after 5 do
				ping_to(g, 1, 2)
			end

			after 10 do
				ccn_put(g, 1, "test.txt")
			end

			after 15 do
				ccn_get_ip(g, 2, "ccnx:/snu.ac.kr/test.txt", "dhkim", "mmlab2015", "147.46.216.250")
			end

			after 20 do
				ccn_get(g, 3, "ccnx:/snu.ac.kr/test.txt", "test")
			end

			after 25 do
				ccn_get_via_gw(group('gwgens'), "ccnx:/snu.ac.kr/test.txt", "hwlee", "mmlab2015", "147.46.215.152")
			end

			after 200 do
				done!
			end
		end
	end
end
