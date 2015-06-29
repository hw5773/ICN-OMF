require './ICN_api'

def_property('vmgen', 'vmgen', 'Name of vmgen')

defGroup('init', 'mbox2@mbox1')
defGroup('vmgens', prop.vmgen)

onEvent :ALL_UP do
	info "value is #{ARGV[-5]}"
	after 5 do
		group('vmgens') do |g|
			if(ARGV[-1].to_i != 0) 
				ccn_setting(g, ARGV)
				time = 57 * (ARGV[-5].to_i + 4) + 30
			else
				time = 10
			end

#---------------------------- You can put the command between this comments
			after time do
				pingGW(g, 1)
				pingGW(g, 2)

				after 5 do
					ccnput(g, 1)
				end

				after 10 do
					ccnget(g, 1)
				end

				after 15 do
					ccnget(g, 2)
				end

				after 30 do
					done!
				end
			end
#---------------------------- experiment end
		end
	end
end
