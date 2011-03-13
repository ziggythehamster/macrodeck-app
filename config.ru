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
require "behaviors/postal_code_behavior"
require "behaviors/title_behavior"

# Load the config file.
puts ">>> Loading configuration."
cfg = MacroDeck::Config.new(File.join(File.dirname(__FILE__), "config", "macrodeck.yml"))

# Start the MacroDeck platform.
puts ">>> Starting MacroDeck Platform on macrodeck-#{cfg.environment}"
MacroDeck::Platform.start!("macrodeck-#{cfg.environment}")
MacroDeck::PlatformDataObjects.define!

puts ">>> MacroDeck Platform started."

# Run our app
use MacroDeck::App, cfg
run Sinatra::Application

# vim:set ft=ruby
