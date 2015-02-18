#!/usr/bin/env ruby

require 'pp'
require 'erb'
require 'optparse'

def parseOptions
	options = {}
	OptionParser.new do |opts|
		opts.banner = "Usage: vagrantfile.rb [options]"

		opts.on("--vsphere_host=address", "vSphere address") do |val|
			options[:vsphere_host] = val
		end

		opts.on("--vsphere_user=name", "vSphere user name") do |val|
			options[:vsphere_user] = val
		end

		opts.on("--vsphere_password=password", "vSphere user password") do |val|
			options[:vsphere_password] = val
		end

		opts.on("--vsphere_cr=name", "vSphere compute resource name") do |val|
			options[:vsphere_cr] = val
		end

		opts.on("--vsphere_rp=name", "vSphere resource pool name") do |val|
			options[:vsphere_rp] = val
		end

		opts.on("--vsphere_template=name", "VM template name") do |val|
			options[:vsphere_template] = val
		end

		opts.on("--vsphere_dc=name", "vSphere date center name") do |val|
			options[:vsphere_dc] = val
		end

		opts.on("--vsphere_vm=name", "Name of VM to be created") do |val|
			options[:vsphere_vm] = val
		end

		opts.on('-h', '--help', "Print usage") do
			puts opts
		end
	end.parse!

	[:vsphere_host, :vsphere_user, :vsphere_password, :vsphere_cr, :vsphere_rp, :vsphere_template, :vsphere_dc, :vsphere_vm].each do |option|
		raise "Option '#{option}' must be specified!" if options[option].nil?
	end

	return options
end

def generate dst, options

	src = "#{File.dirname $0}/../templates/Vagrantfile.erb"
	puts "Generating #{src}"

	template = File.read(src)
	result = ERB.new(template).result binding
	File.write(dst, result)
end

options = parseOptions
generate 'Vagrantfile', options

