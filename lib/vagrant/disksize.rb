#require "vagrant/disksize/version"
begin
  require 'vagrant'
rescue LoadError
  raise 'The vagrant-disksize plugin must be run within vagrant.'
end


module Vagrant
  module Disksize
    class Plugin < Vagrant.plugin('2')

      name 'vagrant-disksize'

      description <<-DESC
      Provides the ability to resize VirtualBox disks at creation time,
      so they don't need to be the same size as the default for the box.
      Filesystems are not resized by this code.
      DESC

      config 'disksize' do
        require_relative 'disksize/config'
        Config
      end

      action_hook(:disksize, :machine_action_up) do |hook|
        require_relative 'disksize/actions'

        # TODO Ensure we are using the VirtualBox provider
        hook.before(VagrantPlugins::ProviderVirtualBox::Action::Boot, Action::ResizeDisk)
      end
    end
  end
end
