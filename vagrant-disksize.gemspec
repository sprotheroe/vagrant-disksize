# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vagrant/disksize/version'

Gem::Specification.new do |spec|
  spec.name          = "vagrant-disksize"
  spec.version       = Vagrant::Disksize::VERSION
  spec.authors       = ["Simon Protheroe"]
  spec.email         = ["protheroe@gmail.com"]

  spec.summary       = %q{Vagrant plugin to resize VirtualBox disks}
  spec.description   = %q{Vagrant plugin to resize VirtualBox disks at creation time}
  spec.homepage      = "https://github.com/sprotheroe/vagrant-disksize"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
end
