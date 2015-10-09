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

module OmfRc::ResourceProxy::GWfactory
	include OmfRc::ResourceProxyDSL

	register_proxy :gwgen
#	register_proxy "#{ARGV[0]}_gwf".to_sym
	utility :common_tools
	utility :gwcontrol

	hook :before_ready do |res|
		res.property.vms_path ||= "/var/lib/libvirt/images"
		res.property.vm_list ||= []
	end

	hook :before_create do |res, type, opts = nil|
		if type.to_sym != :gw
			raise "This resource only creates VM! (Cannot create a resource #{type})"
		end
	end

	hook :after_create do |res, child_res|
		logger.info "Created new child GW: #{child_res.uid}"
		res.property.vm_list << child_res.uid
	end

    property :subnet, :default => 0
    property :act, :default => :stop
	property :prepare, :default => 0
    
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

	work :gateway_init do |res|
		res.send("prepare_gw")
		res.property.prepare = res.property.prepare + 1
		logger.info "stage is #{res.property.prepare}"
		 res.membership.each do |m|
	        res.inform(:status, {uid: res.uid, prepare: res.property.prepare.to_i}, res.membership_topics[m])
		end
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
end

module OmfRc::ResourceProxy::GW
	include OmfRc::ResourceProxyDSL

	register_proxy :gw, :create_by => :gwgen
#	register_proxy :gw, :create_by => "#{ARGV[0]}_gwf".to_sym
	utility :common_tools
	utility :libvirt
	utility :vmbuilder
	utility :gwcontrol

	HYPERVISOR_DEFAULT = :kvm
	HYPERVISOR_URI_DEFAULT = 'qemu:///system'
	VIRTUAL_MNGT_DEFAULT = :libvirt
	IMAGE_BUILDER_DEFAULT = :vmbuilder
	VM_NAME_DEFAULT_PREFIX = "gw"
	VM_DIR_DEFAULT = "/var/lib/libvirt/images"
	VM_OS_DEFAULT = 'ubuntu'

	VM_DEF_DEFAULT = ""
	VM_ORIGINAL_DEFAULT = "gw"
	OMF_DEFAULT = Hashie::Mash.new({
		server: '147.46.215.152',
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
	property :reponame, :default => "snu.ac.kr"
	property :eth_ip
	property :target_eth_ip
	property :macAddress
	property :target_file

	property :role
	property :back
	property :stage, :default => 0
	property :back_id
	property :back_password
	property :back_address
	
	work :execute_cmd do |res,cmd,intro_msg,error_msg,success_msg|
		logger.info "#{intro_msg} with: '#{cmd}'"
		result = `#{cmd} 2>&1`
		if $?.exitstatus != 0
			res.log_inform_error "#{error_msg}: '#{result}'"
			false
		else
			logger.info "#{success_msg}: '#{result}'"
			true
		end
	end

	configure :target_file do |res, value|
		res.property.target_file = value
		logger.info "The target file is set to #{value}."
	end

	configure :back_id do |res, value|
		res.property.back_id = value
		logger.info "The return id is set to #{value}."
	end

	configure :back_address do |res, value|
		res.property.back_address = value
		logger.info "The mac return address is set to #{value}."
	end

	configure :back_password do |res, value|
		res.property.back_password = value
		logger.info "The return password is set to #{value}."
	end

	configure :macAddress do |res, value|
		res.property.macAddress = value
		logger.info "The mac address is set to #{value}."
	end

	work :eth_gw do |res|
		res.send("set_eth_gw")
		res.property.stage = res.property.stage + 1
		logger.info "#{res.property.vm_name}'s stage is #{res.property.stage}"
		res.membership.each do |m|
			res.inform(:status, {uid: res.uid, stage: res.property.stage.to_i}, res.membership_topics[m])
		end
	end

	work :get_mac_gw do |res|
		res.send("get_mac_addr")
		res.property.stage = res.property.stage + 1
		logger.info "#{res.property.vm_name}'s stage is #{res.property.stage}"
		res.membership.each do |m|
			res.inform(:status, {uid: res.uid, stage: res.property.stage.to_i}, res.membership_topics[m])
		end
	end

#	work :ccn_gw do |res|
#		res.send("set_ccn_gw")
#		res.property.stage = res.property.stage + 1
#		logger.info "#{res.property.vm_name}'s stage is #{res.property.stage}"
#		res.membership.each do |m|
#			res.inform(:status, {uid: res.uid, stage: res.property.stage.to_i}, res.membership_topics[m])
#		end
#	end

	work :ccn_get_via_gw_gw do |res|
		res.send("ccn_get_via_gw")
		logger.info "#{res.property.back_address}'s request is satisfied"
	end

	configure :back_address do |res, value|
		res.property.back_address = value
		logger.info "The file will back to #{res.property.back_address}"
	end

	configure :role_set do |res, value|
		res.property.role = value
		logger.info "#{res.property.vm_name}'s role is #{res.property.role}"
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
		res.send("#{act}_gw")
		res.property.action = value
	end

	configure :ccngettarget do |res, value|
		res.property.ccngettarget = value
	end

	work :complete_gw do |res|
		res.property.stage = res.property.stage + 1
		logger.info "#{res.property.vm_name} is set"
		logger.info "#{res.property.vm_name}'s stage is #{res.property.stage}"
		res.membership.each do |m|
			res.inform(:status, {uid: res.uid, stage: res.property.stage.to_i}, res.membership_topics[m])
		end
	end

	work :ccn_table_gw do |res|
		res.send("making_ccn_table")
		res.property.stage = res.property.stage + 1
		logger.info "#{res.property.vm_name} is set"
		logger.info "#{res.property.vm_name}'s stage is #{res.property.stage}"
		res.membership.each do |m|
			res.inform(:status, {uid: res.uid, stage: res.property.stage.to_i}, res.membership_topics[m])
		end
	end

	work :ccn_gw do |res|
		res.send("set_ccn_gw")
		res.property.stage = res.property.stage + 1
		logger.info "#{res.property.vm_name} is set"
		logger.info "#{res.property.vm_name}'s stage is #{res.property.stage}"
		res.membership.each do |m|
			res.inform(:status, {uid: res.uid, stage: res.property.stage.to_i}, res.membership_topics[m])
		end
	end

	work :ccn_get_gw do |res|
		res.send("ccn_get_file")
	end

	work :ccn_put_gw do |res|
		res.send("ccn_put_file")
	end

	work :get_name_gw do |res|
		if res.property.ready
			success = res.send("get_name")
		else
			res.log_inform_error "Getting the name failed"
		end
	end

	work :ping_gw_gw do |res|
		if res.property.ready
			success = res.send("ping_gw")
		else
			res.log_inform_warn "Ping failed"
		end
	end

	work :set_ip_gw do |res|
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

	work :get_ip_gw do |res|
		if res.property.ready
			success = res.send("get_ip")
		else
			res.log_inform_warn "Cannot get the management IP of the #{res.property.vm_name}"
		end
	end

	work :change_ip_gw do |res|
		if res.property.ready
			success = res.send("change_ip")
		else
			res.log_inform_warn "Cannot change the IP address"
		end
	end

	work :define_gw do |res|
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

	work :attach_gw do |res|
		unless !res.property.vm_name.nil? || !res.property.vm_name == ""
			res.log_inform_error "Cannot attach VM, name not set" +
				"(name: '#{res.property.vm_name})'"
		else
			if res.property.state.to_sym == :stopped
				res.property.ready = res.send("attach_vm_with_#{res.property.virt_mngt}")
				res.inform(:status, Hashie::Mash.new({:status => {:ready => res.property.ready}}))
			else
				res.log_inform_warn "Cannot attach VM: it is not stopped" +
				"(name: '#{res.property.vm_name}' - state: #{res.property.state})"
			end
		end
	end

	work :clone_from_gw do |res|
		unless !res.property.vm_name.nil? || !res.property.vm_name == "" ||
			!res.image_directory.nil? || !res.image_directory == ""
			res.log_inform_error "Cannot clone VM: name or directory not set " +
				"(name: '#{res.property.vm_name}' - dir: '#{res.property.image_directory}')"
		else
			if res.property.state.to_sym == :stopped
				vmname = File.open("./vmname", "a")
				vmname.write(res.property.vm_name+"\n")
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

	work :run_gw do |res|
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

	work :delete_gw do |res|
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
		info ">>> Starting GW factory"
		gwgen = OmfRc::ResourceFactory.new(:gwgen, opts.merge(uid: 'gwgen'))
#		factory = OmfRc::ResourceFactory.new("#{ARGV[0]}_gwf", opts.merge(uid: "#{ARGV[0]}_gwf"))

		comm.on_interrupted { gwgen.disconnect }
#		comm.on_interrupted { factory.disconnect }
	end
end
