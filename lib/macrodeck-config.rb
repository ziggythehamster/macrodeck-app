# Loads the config file for the current environment.

require "yaml"
require "sinatra"

module MacroDeck
	class Config
		attr_reader :environment
		attr_reader :layout

		def initialize(yaml_path)
			@config = YAML::load(yaml_path)
			@environment = Sinatra::Application.environment
			if @config[@environment]
				@layout = @config[@environment]["layout"].nil? ? "layout.erb" : @config[@environment]["layout"]
			end
		end
	end
end

# vim:set ft=ruby
