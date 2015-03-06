#!/usr/bin/env ruby

require 'pp'
require 'optparse'

def parseOptions
	options = {}
	OptionParser.new do |opts|
		opts.banner = "Usage: vagrantfile.rb [options]"

		opts.on("--plan=name", "Test plan name") do |val|
			options[:plan] = val
		end

		opts.on("--class=name", "Test class name") do |val|
			options[:class] = val
		end

		opts.on("--test_app=name", "Name of test application") do |val|
			options[:test_app] = val
		end
		
		opts.on("--results=path", "Path to xml with test results") do |val|
			options[:results] = val
		end
		
		opts.on('-h', '--help', "Print usage") do
			puts opts
		end
	end.parse!

	[:plan, :class, :test_app, :results].each do |option|
		raise "Option '#{option}' must be specified!" if options[option].nil?
	end

	return options
end

def ssh_config dest
	command = "vagrant ssh-config > #{dest}"
	puts("Executing: #{command}")
	raise 'Unable to dump vagrant ssh configuration' if system(command) != true
end

def sync ssh_config, app_path
	command = "rsync -avH -e 'ssh -F #{ssh_config}' #{app_path} default:"
	puts("Executing: #{command}")
	raise "Unable to sync data into vagrant VM." if system(command) != true
end

def run app_name, plan, class_name, results_file
	command = "vagrant ssh -c \"cd \\\"#{app_name}\\\"; java -Xmx512m -classpath \\\"lib/*\\\" #{class_name} -planid=#{plan} -logall -junitXml \\\"#{results_file}\\\"\""
	puts("Executing: #{command}")

	if system(command) != true
	       puts "Test execution failed."
	       return 1
	end
end

def download_results ssh_config, app_path, results_file
	command = "scp -F \"#{ssh_config}\" \"default:#{app_path}/#{results_file}\" \"#{results_file}\""
	puts("Executing: #{command}")
	raise "Unable to download test results file." if system(command) != true
end

ssh_config = 'ssh-config'

options = parseOptions

ssh_config(ssh_config)

app_path = Dir.glob("#{options[:test_app]}*").select {|f| not f =~ /\.gz$/}[0]

sync(ssh_config, app_path)

result = run(app_path, options[:plan], options[:class], File.basename(options[:results]))

download_results(ssh_config, app_path, File.basename(options[:results]))

exit result

