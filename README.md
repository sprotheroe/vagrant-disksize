# vagrant-disksize

A Vagrant plugin to resize disks in VirtualBox


## Installation


```shell
vagrant plugin install vagrant-disksize
```

## Usage

Set the size you want for your disk in your Vagrantfile. For example

```ruby
Vagrant.configure('2') do |config|
  config.vm.box = 'ubuntu/xenial64'
  config.disksize.size = '50GB'
end
```

You can specify the size as a raw number (in bytes) or using KB, MB, GB
or TB (though I'd be interested to learn more if you are using Vagrant
to create multi-terabyte disks). Internally the size will be converted
to megabytes, for ease of interaction with VirtualBox. If the value you
specify isn't a whole number of megabytes, it will be rounded up, to
ensure you have at least the capacity you requested. Note that the
plugin uses the original definitions so, for example, 1 GB = 1024 MB;
we don't have to use hardware manufacturer marketing maths here and
it makes the internal maths easier.

### Shrinking the VDI file

Internally the plugin will convert the format of the virtual machine's
disk file to the VDI format.  The new disk is created with dynamic
sizing, meaning the physical `.vdi` disk file on the host will
start small, and grow over time as data is added in the guest.

Unfortunately, by default, the `.vdi` file will never shrink back,
even if one deletes all the data inside the guest.  This is not
a side-effect of this plugin, it's how virtualbox works with
virtual hard disks.

There is a feature in virtualBox that allows to turn on the TRIM
feature on non-rotational disks.  This plugin turns on this
feature when re-attaching the resized disk to the VM.

A nice effect of this TRIM feature, applied to VirtualBox, is that
when the guest OS issues the TRIM request on the virtual hard disk,
it causes the corresponding `.vdi` physical file on the host to
shrink.

Since TRIM takes some time to execute, it's not enabled by default
on Linux guest OS such as Ubuntu.  To use this feature in the
guest:

1. Inside the guest, delete unused files to make room in the file
   system.
2. To reclaim most of that space on the corresponding `.vdi` file
   on the host, make the guest OS issue the TRIM command on the
   virtual hard disk.  This can be different per guest OS.
   On Linux-based guests like Ubuntu, run `sudo fstrim /`.


## Limitations

At present only the first disk will be resized. That seems to be OK for
typical boxes such as the official Ubuntu images for Xenial, but there may
well be other configurations where the first disk found isn't the main HDD.

The plugin only works with VirtualBox but it will issue an error message
and then disable itself if you try to use it with another provider.

Disks can only be increased in size. There is no facility to shrink a disk.

Depending on the guest, you may need to resize the partition and the filesystem
from within the guest. At present the plugin only resizes the underlying disk.

This hasn't been tested on a wide variety of versions of Vagrant or VirtualBox.
It works for, at least, Vagrant 1.8.5 and VirtualBox 5.1.x, but any
feedback about other versions, particularly older ones, would be much appreciated.

## Development

After checking out the repo, run `bin/setup` to install dependencies.
You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.
To release a new version, update the version number in `version.rb`, and then
run `bundle exec rake release`, which will create a git tag for the version,
push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sprotheroe/vagrant-disksize.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

