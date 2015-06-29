require 'omf_common'

def create_vm(virtual_machine_factory, num)
  virtual_machine_factory.create(:virtual_machine, uid: "vm#{num}", vm_original_clone: "new") do |reply_msg|
#  vmgen.configure(action:    
    if reply_msg.success?
      vm = reply_msg.resource

      vm.on_subscribed do
	info ">>> Connected to newly created #{reply_msg[:hrn]}(id: #{reply_msg[:res_id]}, name : #{reply_msg[:vm_name]}, original_clone : #{reply_msg[:vm_original_clone]})"

        info "Change name from #{reply_msg[:vm_name]} to myVM"

        vm.configure(vm_os: "ubuntu") do |msg|
          info ">>> vm_os : #{msg[:vm_os]}"
        end

	vm.configure(vm_name: "vm#{num}") do |msg|
          info ">>> vm_name : #{msg[:vm_name]}"
        end

        vm.configure(image_directory: "/home/dhkim/image") do |msg|
          info ">>> image_directory : #{msg[:image_directory]}"
        end

	# query the hypervisor used	
	vm.request([:hypervisor]) do |msg|
          info ">>> hypervisor : #{msg[:hypervisor]}"
        end

        info ">>> waiting for clonning"
        OmfCommon.eventloop.after(5) do
          vm_clone = vm.configure(action: :clone_from)
          OmfCommon.eventloop.after(30) do
            vm.request([:ready]) do |msg|
              info ">>> vm#{num} is ready : #{msg[:ready]}"
            end
          end

	# need some time to run because of clonning time
          OmfCommon.eventloop.after(20) do 
            vm.configure(action: :run)
            info ">>> vm#{num} is running"
          end
 
#          OmfCommon.eventloop.after(10) do
#            vm.request([:vm_name]) do |msg|
#              info ">>> #{msg[:vm_name]} is cloned"
#              vm.configure(action: :run)
#              info ">>> #{msg[:vm_name]} is running"
#              virtual_machine_factory.release_vm(vm)
#            end
#          end
        end
      end
    else
      error ">>> Resource creation failed - #{reply_msg[:reason]}"
    end
  end
end

def require_vm(virtual_machine_factory, vm)
  info ">>> Release vm"
  virtual_machine_factory.release(vm) do |reply_msg|
    unless reply_msg.error?
      info "VM #{reply_msg[:res_id]} is released"
    else
      error "request error"
    end
  end
end

def release_vm(virtual_machine_factory, vm)
  info ">>> Release vm"
  virtual_machine_factory.release(vm) do |reply_msg|
    info "VM#{reply_msg[:res_id]} released"
    OmfCommon.comm.disconnect
  end
end

OmfCommon.init(:development, communication: { url: 'xmpp://147.46.216.155' }) do
  arr = [1, 2]
  OmfCommon.comm.on_connected do |comm|
    info "VM test script >> Connected to XMPP"
    info "Now clone the VM"

    comm.subscribe('virtual_machine_factory') do |virtual_machine_factory|
      unless virtual_machine_factory.error?
        arr.each do |n|
          create_vm(virtual_machine_factory, n)
        end
        info "vm create is complete"
      else
        error virtual_machine_factory.inspect
      end
    end

    list = getResources()
    print list

    OmfCommon.eventloop.after(30) { comm.disconnect }
    comm.on_interrupted { comm.disconnect }
  end
end
