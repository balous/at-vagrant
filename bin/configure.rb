#!/usr/bin/env ruby

require 'pp'
require 'erb'
require 'optparse'
require 'fileutils'
require 'xmlsimple'

def parseOptions
	options = {}
	OptionParser.new do |opts|
		opts.banner = "Usage: vagrantfile.rb [options]"

		opts.on("--test_app=name", "Name of test application") do |val|
			options[:test_app] = val
		end

		opts.on("--packages_path=path", "Path to packages to test") do |val|
			options[:packages_path] = val
		end

		opts.on("--product=name", "Name of product as understood by AT framework") do |val|
			options[:product] = val
		end

		opts.on('-h', '--help', "Print usage") do
			puts opts
		end
	end.parse!

	[:test_app, :packages_path, :product].each do |option|
		raise "Option '#{option}' must be specified!" if options[option].nil?
	end

	return options
end

def app_path name
	path = Dir.glob("#{name}*")[0]
	return path
end

def copy_packages src_dir, app_path
	dst_dir = "#{app_path}/packages"
	FileUtils.mkdir_p(dst_dir)

	packages_build = XmlSimple.xml_in(File.read("#{src_dir}/packages.txt"))["package"]

	packages_test = []
	packages_build.each do |package|
		src = "#{src_dir}/#{package['file']}"
		dst = "./packages/#{File.basename(package['file'])}"

		packages_test.push({'name' => package['id'], 'path' => dst})

		puts "Copying #{src}"
		FileUtils.copy(src, "#{app_path}/#{dst}")
	end

	return packages_test
end

def unpackApp name
	tgz = Dir.glob("#{name}*.tar.gz")[0]
	puts "Unpacking test app"
	raise "Unable to unpack app archive" if system("tar xfzv \"#{tgz}\"") != true
end

def testConfig app_path, product, packages

	src = "#{File.dirname($0)}/../templates/global-test-config.xml.erb"
	dst_dir = "#{app_path}/conf"
	dst = "#{dst_dir}/global-test-config.xml"

	puts "Generating #{dst}"
	
	FileUtils.mkdir_p(dst_dir)

	template = File.read(src)
	result = ERB.new(template).result binding
	File.write dst, result
end

options = parseOptions

unpackApp options[:test_app]

app_path = app_path(options[:test_app])

packages = copy_packages(options[:packages_path], app_path)

testConfig app_path, options[:product], packages
