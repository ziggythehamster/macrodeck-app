# Loads the config file for the current environment.

require "yaml"
require "sinatra"

module MacroDeck
	class Config
		attr_reader :environment
		attr_reader :layout
		attr_reader :view_dir
		attr_reader :path_prefix

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
			end
		end
	end
end

# vim:set ft=ruby
