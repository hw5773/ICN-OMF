require 'omf_rc'
require 'omf_rc/resource_factory'

$stdout.sync = true

op_mode = :development

opts = {
	communication: { url: 'xmpp://147.46.216.250' },
	eventloop: { type: :em },
	logging: {
		level: 'info'
	}
}

module OmfRc::ResourceProxy::VMfactory
	include OmfRc::ResourceProxyDSL

	register_proxy :vmgen
#	register_proxy "#{ARGV[0]}_vmf".to_sym
	utility :common_tools
	utility :vmcontrol
	utility :graph_descriptor

	hook :before_ready do |res|
		res.property.vms_path ||= "/var/lib/libvirt/images"
		res.property.vm_list ||= []
	end

	hook :before_create do |res, type, opts = nil|
		if type.to_sym != :vm
			raise "This resource only creates VM! (Cannot create a resource #{type})"
		end
	end

	hook :after_create do |res, child_res|
		logger.info "Created new child VM: #{child_res.uid}"
		res.property.vm_list << child_res.uid
	end

	property :node, :default => 3
	property :edge, :default => 2
	property :subnet, :default => 0
	property :prepare, :default => 0
	property :act, :default => :stop
	property :id
	property :target_file, :default => "ccnx:/snu.ac.kr/test.txt"
	property :output_file, :default => "testfile"
	property :graph_mode, :default => 0

	configure :graph_mode do |res, value|
		res.property.graph_mode = value
		logger.info "graph mode is #{value}."
	end

	configure :target_file do |res, value|
		res.property.target_file = value
		logger.info "target file is set to #{value}."
	end

	configure :output_file do |res, value|
		res.property.output_file = value
		logger.info "output file is set to #{value}."
	end

	configure :node do |res, value|
		res.property.node = value
		logger.info "node is set to #{value}."
	end

	configure :edge do |res, value|
		res.property.edge = value
		logger.info "edge is set to #{value}."
	end

	configure :id do |res, value|
		res.property.id = value
		logger.info "id is set to #{value}."
	end

	configure :subnet do |res, value|
		res.property.subnet = value
		logger.info "subnet is set to #{value}."
		res.property.prepare = res.property.prepare + 1
		logger.info "stage is #{res.property.prepare}"
		res.membership.each do |m|
			res.inform(:status, {uid: res.uid, prepare: res.property.prepare.to_i}, res.membership_topics[m])
		end
	end

	configure :act do |res, value|
		logger.info "call #{value}"
		res.send("#{value}")
		res.property.act = value
	end

	work :plus do |res|
		res.property.prepare = res.property.prepare + 1
		logger.info "stage is #{res.property.prepare}"
		res.membership.each do |m|
			res.inform(:status, {uid: res.uid, prepare: res.property.prepare.to_i}, res.membership_topics[m])
		end
	end

	work :graph_init do |res|
		res.send("prepare")		
		res.property.prepare = res.property.prepare + 1
		logger.info "stage is #{res.property.prepare}"
		res.membership.each do |m|
			res.inform(:status, {uid: res.uid, prepare: res.property.prepare.to_i}, res.membership_topics[m])
		end
	end

	work :graph_random do |res|
		res.send("making_random_graph")
		res.property.prepare = res.property.prepare + 1
		logger.info "stage is #{res.property.prepare}"
		res.membership.each do |m|
			res.inform(:status, {uid: res.uid, prepare: res.property.prepare.to_i}, res.membership_topics[m])
		end
	end

	work :graph_description do |res|
		res.send("making_description")
		res.property.prepare = res.property.prepare + 1
		logger.info "stage is #{res.property.prepare}"
		res.membership.each do |m|
			res.inform(:status, {uid: res.uid, prepare: res.property.prepare.to_i}, res.membership_topics[m])
		end
	end

	work :routing_table do |res|
		res.send("making_tables")
		res.property.prepare = res.property.prepare + 1
		logger.info "stage is #{res.property.prepare}"
		res.membership.each do |m|
			res.inform(:status, {uid: res.uid, prepare: res.property.prepare.to_i}, res.membership_topics[m])
		end
	end
end

module OmfRc::ResourceProxy::VM
	include OmfRc::ResourceProxyDSL

	register_proxy :vm, :create_by => :vmgen
#	register_proxy :vm, :create_by => "#{ARGV[0]}_vmf".to_sym
	utility :common_tools
	utility :libvirt
	utility :vmbuilder
	utility :vmcontrol

	HYPERVISOR_DEFAULT = :kvm
	HYPERVISOR_URI_DEFAULT = 'qemu:///system'
	VIRTUAL_MNGT_DEFAULT = :libvirt
	IMAGE_BUILDER_DEFAULT = :vmbuilder
	VM_NAME_DEFAULT_PREFIX = "vm"
	VM_DIR_DEFAULT = "/var/lib/libvirt/images"
	VM_OS_DEFAULT = 'ubuntu'

	VM_DEF_DEFAULT = ""
	VM_ORIGINAL_DEFAULT = "vm"
	OMF_DEFAULT = Hashie::Mash.new({
		server: '147.46.216.250',
#		user: 'dhkim', password: 'mmlab2015',
		topic: nil
		})

	property :use_sudo, :default => true
	property :hypervisor, :default => HYPERVISOR_DEFAULT
	property :hypervisor_uri, :default => HYPERVISOR_URI_DEFAULT
	property :virt_mngt, :default => VIRTUAL_MNGT_DEFAULT
	property :img_builder, :default => IMAGE_BUILDER_DEFAULT
	property :action, :default => :stop
	property :state, :default => :stopped
	property :ready, :default => false
	property :enable_omf, :default => true
	property :vm_name, :default => "#{VM_NAME_DEFAULT_PREFIX}_#{Time.now.to_i}"
	property :image_directory, :default => VM_DIR_DEFAULT
	property :image_path, :default => VM_DIR_DEFAULT
	property :vm_definition, :default => VM_DEF_DEFAULT
	property :vm_original_clone, :default => VM_ORIGINAL_DEFAULT
	property :vm_os, :default => VM_OS_DEFAULT
	property :omf_opts, :default => OMF_DEFAULT
	property :xml_directory, :default => "/etc/libvirt/qemu"
	property :class, :default => ""

	property :manageIP, :default => ""
	property :sn, :default => 0
	property :target, :default => ""
	property :repoName, :default => "ccnx:/snu.ac.kr"
	property :numOfPort, :default => 0
	property :vmIP, :default => []
	property :vmRT, :default => []
	property :macAddress, :default => ""

	property :role
	property :back
	property :back_id
	property :back_password

	property :node, :default => 3
	property :edge, :default => 2
	property :subnet, :default => 0
	property :stage, :default => 0
	property :repoList, :default => []

	property :id
	property :password
	property :ip, :default => "147.46.216.250"

	property :target_file, :default => "ccnx:/snu.ac.kr/test.txt"
	property :output_file, :default => "testfile"
	property :put_file, :default => "test.txt"

	configure :target_file do |res, value|
		res.property.target_file = value
		logger.info "target file is set to #{value}."
	end

	configure :output_file do |res, value|
		res.property.output_file = value
		logger.info "output file is set to #{value}."
	end

	configure :back_id do |res, value|
		res.property.back_id = value
		logger.info "the id to return is set to #{value}."
	end

	configure :back_password do |res, value|
		res.property.back_password = value
		logger.info "the password to return is set."
	end

	work :eth_vm do |res|
		res.send("set_eth")
		res.property.stage = res.property.stage + 1
		logger.info "#{res.property.vm_name}'s stage is #{res.property.stage}"
		res.membership.each do |m|
			res.inform(:status, {uid: res.uid, stage: res.property.stage.to_i}, res.membership_topics[m])
		end
	end

	work :rt_vm do |res|
		res.send("set_rt")
		res.property.stage = res.property.stage + 1
		logger.info "#{res.property.vm_name}'s stage is #{res.property.stage}"
		res.membership.each do |m|
			res.inform(:status, {uid: res.uid, stage: res.property.stage.to_i}, res.membership_topics[m])
		end
	end

	work :xml_revise_vm do |res|
		res.send("making_xml")
		res.property.stage = res.property.stage + 1
		logger.info "#{res.property.vm_name}'s stage is #{res.property.stage}"
		res.membership.each do |m|
			res.inform(:status, {uid: res.uid, stage: res.property.stage.to_i}, res.membership_topics[m])
		end
	end		

	work :ccn_table_vm do |res|
		res.send("making_ccn_table")
		res.property.stage = res.property.stage + 1
		logger.info "#{res.property.vm_name}'s stage is #{res.property.stage}"
		res.membership.each do |m|
			res.inform(:status, {uid: res.uid, stage: res.property.stage.to_i}, res.membership_topics[m])
		end
	end

	work :ccn_vm do |res|
		res.send("set_ccn")
		res.property.stage = res.property.stage + 1
		logger.info "#{res.property.vm_name}'s stage is #{res.property.stage}"
		res.membership.each do |m|
			res.inform(:status, {uid: res.uid, stage: res.property.stage.to_i}, res.membership_topics[m])
		end
	end

	work :complete_vm do |res|
		sleep 30
		res.property.stage = res.property.stage + 1
		logger.info "#{res.property.vm_name}'s set is completed"
		logger.info "#{res.property.vm_name}'s stage is #{res.property.stage}"
		res.membership.each do |m|
			res.inform(:status, {uid: res.uid, stage: res.property.stage.to_i}, res.membership_topics[m])
		end
	end

	work :ccn_get_ip_vm do |res|
		res.send("ccn_get_ip")
		logger.info "#{res.property.back}'s request is satisfied"
	end

	configure :back_address do |res, value|
		res.property.back = value
		logger.info "The file will back to #{res.property.back}"
	end

	configure :role_set do |res, value|
		res.property.role = value
#		res.property.stage = res.property.stage + 1
		logger.info "#{res.property.vm_name}'s role is #{res.property.role}"
#		logger.info "#{res.property.vm_name}'s stage is #{res.property.stage}"
#		res.membership.each do |m|
#			res.inform(:status, {uid: res.uid, stage: res.property.stage.to_i}, res.membership_topics[m])
#		end
	end

	configure :class do |res, value|
		res.property.class = value
	end

	configure :omf_opts do |res, opts|
		if opts.kind_of? Hash
			if res.property.omf_opts.empty?
				res.property.omf_opts = OMF_DEFAULT.merge(opts)
			else
				res.property.omf_opts = res.property.omf_opts.merge(opts)
			end
		else
			res.log_inform_error "OMF option configuration failed! " +
				"Options not passed as Hash (#{opts.inspect})"
		end
		res.property.omf_opts
	end

	configure :vm_name do |res, name|
		res.property.image_path = "#{res.property.image_directory}/#{name}.img"
		res.property.vm_name = name
	end

	configure :action do |res, value|
		act = value.to_s.downcase
		res.send("#{act}_vm")
		res.property.action = value
	end

	configure :ccngettarget do |res, value|
		res.property.ccngettarget = value
	end

	work :ccn_get_vm do |res|
		res.send("ccn_get_file")
	end

	work :ccn_put_vm do |res|
		res.send("ccn_put_file")
	end

	work :get_name_vm do |res|
		if res.property.ready
			success = res.send("get_name")
		else
			res.log_inform_error "Getting the name failed"
		end
	end

	work :ping_gw_vm do |res|
		if res.property.ready
			success = res.send("ping_gw")
		else
			res.log_inform_warn "Ping failed"
		end
	end

	work :set_ip_vm do |res|
		if res.property.ready
			success = res.send("set_ip")
			res.property.stage = res.property.stage + 1
			logger.info "#{res.property.vm_name}'s stage is #{res.property.stage}"
			res.membership.each do |m|
				res.inform(:status, {uid: res.uid, stage: res.property.stage.to_i}, res.membership_topics[m])
			end
		else
			res.log_inform_warn "Cannot set the management IP of the #{res.property.vm_name}"
		end
	end

	work :get_ip_vm do |res|
		if res.property.ready
			success = res.send("get_ip")
		else
			res.log_inform_warn "Cannot get the management IP of the #{res.property.vm_name}"
		end
	end

	work :change_ip_vm do |res|
		if res.property.ready
			success = res.send("change_ip")
		else
			res.log_inform_warn "Cannot change the IP address"
		end
	end

	work :build_vm do |res|
		res.log_inform_warn "Trying to build an already built VM, make sure to " +
			"have the 'overwrite' property set to true!" if res.property.ready
		if res.property.state.to_sym == :stopped
			res.property.ready = res.send("build_img_with_#{res.property.img_builder}")
			res.inform(:status, Hashie::Mash.new({:status => {:ready => res.property.ready}}))
		else
			res.log_inform_error "Cannot build VM image: it is not stopped" +
				"(name: '#{res.property.vm_name}' - state: #{res.property.state})" +
				"- path: '#{res.property.image_path}')"
		end
	end
	
	work :define_vm do |res|
		`sudo cp ./source_codes/vm#{res.property.sn}.xml #{res.property.xml_directory}/vm#{res.property.sn}.xml`
		res.property.vm_definition = "#{res.property.xml_directory}/vm#{res.property.sn}.xml"

		unless File.exist?(res.property.vm_definition)
			res.log_inform_error "Cannot define VM (name: " +
				"'#{res.property.vm_name}'): definition path not set " +
				"or file does not exist (path: '#{res.property.vm_definition}')"
		else
			if res.property.state.to_sym == :stopped
				res.property.ready = res.send("define_vm_with_#{res.property.virt_mngt}")
				res.inform(:status, Hshie::Mash.new({:status => {:ready => res.property.ready}}))
			else
				res.log_inform_warn "Cannot define VM: it is not stopped" +
				"(name: '#{res.property.vm_name}' - state: #{res.property.state})"
			end
		end
	end

	work :attach_vm do |res|
		unless !res.property.vm_name.nil? || !res.property.vm_name == ""
			res.log_inform_error "Cannot attach VM, name not set" +
				"(name: '#{res.property.vm_name})'"
		else
			if res.property.state.to_sym == :stopped
				vmname = File.open("./tmp/vmname", "a")
				vmname.write(res.property.vm_name+"\n")
				f = File.open("./tmp/port."+res.property.sn.to_s)
				res.property.numOfPort = f.read.to_i
				logger.info "numOfPort is #{res.property.numOfPort}"
				File.open("./tmp/vmIP."+res.property.sn.to_s).each do |line|
					(res.property.vmIP ||= []) << line[0..-2]
				end
				logger.info "#{res.property.sn}'s vmIP is #{res.property.vmIP}"
				File.open("./tmp/vmRT."+res.property.sn.to_s).each do |line|
					(res.property.vmRT ||= []) << line[0..-2]
				end
				logger.info "#{res.property.sn}'s vmRT is #{res.property.vmRT}"
	
				res.property.ready = res.send("attach_vm_with_#{res.property.virt_mngt}")
				res.inform(:status, Hashie::Mash.new({:status => {:ready => res.property.ready}}))
				res.property.stage = res.property.stage + 1
				logger.info "#{res.property.vm_name}'s stage is #{res.property.stage}"

			else
				res.log_inform_warn "Cannot attach VM: it is not stopped" +
				"(name: '#{res.property.vm_name}' - state: #{res.property.state})"
			end
		end
	end

	work :clone_from_vm do |res|
		unless !res.property.vm_name.nil? || !res.property.vm_name == "" ||
			!res.image_directory.nil? || !res.image_directory == ""
			res.log_inform_error "Cannot clone VM: name or directory not set " +
				"(name: '#{res.property.vm_name}' - dir: '#{res.property.image_directory}')"
		else
			if res.property.state.to_sym == :stopped
				vmname = File.open("./tmp/vmname", "a")
				vmname.write(res.property.vm_name+"\n")
				f = File.open("./tmp/port."+res.property.sn.to_s)
				res.property.numOfPort = f.read.to_i
				logger.info "numOfPort is #{res.property.numOfPort}"
				File.open("./tmp/vmIP."+res.property.sn.to_s).each do |line|
					(res.property.vmIP ||= []) << line[0..-2]
				end
				logger.info "#{res.property.sn}'s vmIP is #{res.property.vmIP}"
				File.open("./tmp/vmRT."+res.property.sn.to_s).each do |line|
					(res.property.vmRT ||= []) << line[0..-2]
				end
				logger.info "#{res.property.sn}'s vmRT is #{res.property.vmRT}"
				res.property.ready = res.send("clone_vm_with_#{res.property.virt_mngt}")
				res.inform(:status, Hashie::Mash.new({:status => {:ready => res.property.ready}}))
				res.property.stage = res.property.stage + 1
				logger.info "#{res.property.vm_name}'s stage is #{res.property.stage}"
			else
				res.log_inform_warn "Cannot clone VM: it is not stopped" +
				"(name: '#{res.property.vm_name}' - state: #{res.property.state})"
			end
		end
	end

	work :stop_vm do |res|
		if res.property.state.to_sym == :running
			success = res.send("stop_vm_with_#{res.property.virt_mngt}")
			res.property.state = :stopped if success
		else
			res.log_inform_warn "Cannot stop VM: it is not running " +
				"(name: '#{res.property.vm_name}' - state: #{res.property.state})"
		end
	end

	work :run_vm do |res|
		if res.property.state.to_sym == :stopped && res.property.ready
			success = res.send("run_vm_with_#{res.property.virt_mngt}")
			res.property.state = :running if success
			res.property.stage = res.property.stage + 1
			logger.info "#{res.property.vm_name}'s stage is #{res.property.stage}"
			res.membership.each do |m|
				res.inform(:status, {uid: res.uid, stage: res.property.stage.to_i}, res.membership_topics[m])
			end
		else
			res.log_inform_warn "Cannot run VM: it is not stopped or ready yet " +
				"(name: '#{res.property.vm_name}' - state: #{res.property.state})"
		end
	end

	work :delete_vm do |res|
		if res.property.state.to_sym == :stopped && res.property.ready
			success = res.send("delete_vm_with_#{res.property.virt_mngt}")
			res.property.ready = false if success
		else
			res.log_inform_warn "Cannot delete VM: it is not stopped or ready yet " +
				"(name: '#{res.property.vm_name}' - state: #{res.property.state} " +
				"- ready: #{res.property.ready}"
		end
	end
end

OmfCommon.init(op_mode, opts) do |el|
	OmfCommon.comm.on_connected do |comm|
		info ">>> Starting VM factory"
		vmgen = OmfRc::ResourceFactory.new(:vmgen, opts.merge(uid: 'vmgen'))
#		factory = OmfRc::ResourceFactory.new("#{ARGV[0]}_vmf".to_sym", opts.merge(uid: "#ARGV[0]_vmf"))

		comm.on_interrupted { vmgen.disconnect }
#		comm.on_interrupted { factory.disconnect }
	end
end
