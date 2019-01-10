module Vagrant
  module Disksize
    class Action

      class ResizeDisk

        # NOTE - size is represented in MB throughout this class, for ease of using with VirtualBox

        # Creates infix for VBoxManage commands (driver.execute)
        # according to VirtualBox version
        VB_Meta = VagrantPlugins::ProviderVirtualBox::Driver::Meta.new()
        if VB_Meta.version >= '5.0'
          MEDIUM = 'medium'
        else
          MEDIUM = 'hd'
        end

        def initialize(app, env)
          @app = app
          @machine = env[:machine]
          @enabled = true
          if @machine.provider.to_s !~ /VirtualBox/
            @enabled = false
            env[:ui].error "The vagrant-disksize plugin only supports VirtualBox at present. Disk size will not be changed."
          end
        end

        def call(env)
          # Resize disk itself before boot
          if @enabled
            requested_size = @machine.config.disksize.size
            if requested_size
              ensure_disk_resizable(env)
              resize_disk(env, requested_size)
            end
          end

          # Allow middleware chain to continue so VM is booted
          @app.call(env)

          # TODO Possibly resize partition and filesystem here if needed
        end

        private

        def ensure_disk_resizable(env)
          driver = @machine.provider.driver
          disks = identify_disks(driver)
          # TODO Shouldn't assume that the first disk is the one we want to resize
          unless disk_resizeable? disks.first
            old_disk = disks.first
            new_disk = generate_resizable_disk(old_disk)
            unless File.exist? new_disk[:file]
              clone_as_vdi(driver, old_disk, new_disk)
              attach_disk(driver, new_disk)
              remove_disk(driver, old_disk)
            end
          end
        end

        def resize_disk(env, req_size)
          driver = @machine.provider.driver
          disks = identify_disks(driver)
          target = disks.first    # TODO Shouldn't assume that the first disk is the one we want to resize

          old_size = get_disk_size(driver, target)
          if old_size < req_size
            grow_vdi(driver, target, req_size)
            new_size = get_disk_size(driver, target)
            env[:ui].success "Resized disk: old #{old_size} MB, req #{req_size} MB, new #{new_size} MB"
            env[:ui].success "You may need to resize the filesystem from within the guest."
          elsif old_size > req_size
            env[:ui].error "Disk cannot be decreased in size. #{req_size} MB requested but disk is already #{old_size} MB."
          end
        end

        def clone_as_vdi(driver, src, dst)
          driver.execute("clone#{MEDIUM}", src[:file], dst[:file], '--format', 'VDI')
        end

        def grow_vdi(driver, disk, size)
          driver.execute("modify#{MEDIUM}", disk[:file], '--resize', size.to_s)
        end

        def attach_disk(driver, disk)
          parts = disk[:name].split('-')
          controller = parts[0]
          port = parts[1]
          device = parts[2]
          driver.execute('storageattach', @machine.id, '--storagectl', controller, '--port', port, '--device', device, '--type', 'hdd',  '--medium', disk[:file])
        end

        def remove_disk(driver, disk)
          driver.execute("closemedium", disk[:file], '--delete')
        end

        def get_disk_size(driver, disk)
          size = nil
          driver.execute("show#{MEDIUM}info", disk[:file]).each_line do |line|
            if line =~ /Capacity:\s+([0-9]+)\s+MB/
              size = $1.to_i
            end
          end
          size
        end

        def identify_disks(driver)
          vminfo = get_vminfo(driver)
          disks = []
          disk_keys = vminfo.keys.select { |k| k =~ /-ImageUUID-/ }
          disk_keys.each do |key|
            uuid = vminfo[key]
            if is_disk(driver, uuid)
              disk_name = key.gsub(/-ImageUUID-/,'-')
              disk_file = vminfo[disk_name]
              disks << {
                uuid: uuid,
                name: disk_name,
                file: disk_file
              }
            end
          end
          disks
        end

        def get_vminfo(driver)
          vminfo = {}
          driver.execute('showvminfo', @machine.id, '--machinereadable', retryable: true).split("\n").each do |line|
            parts = line.partition('=')
            key = unquoted(parts.first)
            value = unquoted(parts.last)
            vminfo[key] = value
          end
          vminfo
        end

        def is_disk(driver, uuid)
          begin
            driver.execute("showmediuminfo", 'disk', uuid)
            true
          rescue
            false
          end
        end

        def generate_resizable_disk(disk)
          src = disk[:file]
          src.gsub!(/\\+/, '/')
          src_extn = File.extname(src)
          src_path = File.dirname(src)
          src_base = File.basename(src, src_extn)
          dst = File.join(src_path, src_base) + '.vdi'
          disk.merge({ uuid: "(undefined)", file: dst })
        end

        def disk_resizeable?(disk)
          disk[:file].end_with? '.vdi'
        end

        def unquoted(s)
          s.gsub(/\A"(.*)"\Z/,'\1')
        end
      end

    end
  end
end
