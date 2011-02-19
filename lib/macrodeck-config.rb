# Loads the config file for the current environment.

require "yaml"
require "sinatra"

module MacroDeck
	class Config
		attr_reader :environment
		attr_reader :layout

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
			end
		end
	end
end

# vim:set ft=ruby
