#!/usr/bin/env ruby
# MacroDeck Sample Application
# (C) 2011 MacroDeck
#
# License: GPL-2, MacroDeck owns all contributions and can re-release them under other licenses

$LOAD_PATH << File.join(File.dirname(__FILE__), "lib")

# Ruby libraries.
require "rubygems"
require "builder"
require "sinatra"
require "macrodeck-platform/init"
require "macrodeck-app"
require "macrodeck-config"
require "macrodeck-behavior"
require "behaviors/abbreviation_behavior"
require "behaviors/address_behavior"
require "behaviors/description_behavior"
require "behaviors/end_time_behavior"
require "behaviors/event_type_behavior"
require "behaviors/fare_behavior"
require "behaviors/geo_behavior"
require "behaviors/phone_number_behavior"
require "behaviors/postal_code_behavior"
require "behaviors/recurrence_behavior"
require "behaviors/start_time_behavior"
require "behaviors/title_behavior"
require "behaviors/url_behavior"

# Load the config file.
puts ">>> Loading configuration."
cfg = MacroDeck::Config.new(File.join(File.dirname(__FILE__), "config", "macrodeck.yml"))

# Start the MacroDeck platform.
puts ">>> Starting MacroDeck Platform on macrodeck-#{cfg.environment}"
MacroDeck::Platform.start!("macrodeck-#{cfg.environment}")
MacroDeck::PlatformDataObjects.define!

puts ">>> MacroDeck Platform started."

# Run our app
map cfg.path_prefix do
	MacroDeck::App.configuration = cfg
	MacroDeck::App.set :views, File.join(File.dirname(__FILE__), ::MacroDeck::App.configuration.view_dir.to_s)
	MacroDeck::App.set :public, File.join(File.dirname(__FILE__), "public")

	run MacroDeck::App
end

# vim:set ft=ruby
