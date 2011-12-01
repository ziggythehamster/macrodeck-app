# Loads the config file for the current environment.

require "yaml"
require "sinatra"

module MacroDeck
	class Config
		attr_reader :environment
		attr_reader :layout
		attr_reader :view_dir
		attr_reader :path_prefix
		attr_reader :turk_path_prefix
		attr_reader :turk_sandbox
		attr_reader :aws_access_key
		attr_reader :aws_secret_access_key

		def initialize(yaml_path)
			File.open(yaml_path) do |yml|
				@config = YAML::load(yml)
			end
			@environment = Sinatra::Application.environment.to_sym
			if @config[@environment.to_s]
				if @config[@environment.to_s]["layout"]
					@layout = @config[@environment.to_s]["layout"]
				else
					@layout = "layout"
				end

				if @config[@environment.to_s]["view_dir"]
					@view_dir = @config[@environment.to_s]["view_dir"]
				else
					@view_dir = "views"
				end

				if @config[@environment.to_s]["path_prefix"]
					@path_prefix = @config[@environment.to_s]["path_prefix"]
				else
					@path_prefix = "/"
				end

				if @config[@environment.to_s]["turk_path_prefix"]
					@turk_path_prefix = @config[@environment.to_s]["turk_path_prefix"]
				else
					@turk_path_prefix = "/turk/"
				end

				if @config[@environment.to_s]["turk_sandbox"]
					@turk_sandbox = @config[@environment.to_s]["turk_sandbox"]
				else
					@turk_sandbox = true
				end

				if @config[@environment.to_s]["aws_access_key"]
					@aws_access_key = @config[@environment.to_s]["aws_access_key"]
				else
					@aws_access_key = ""
				end

				if @config[@environment.to_s]["aws_secret_access_key"]
					@aws_secret_access_key = @config[@environment.to_s]["aws_secret_access_key"]
				else
					@aws_secret_access_key = ""
				end
			end
		end
	end
end

# vim:set ft=ruby
