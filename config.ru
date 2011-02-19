#!/usr/bin/env ruby
# MacroDeck Sample Application
# (C) 2011 MacroDeck
#
# License: GPL-2, MacroDeck owns all contributions and can re-release them under other licenses

$LOAD_PATH << File.join(File.dirname(__FILE__), "lib")

# Ruby libraries.
require "rubygems"
require "sinatra"
require "macrodeck-platform/init"
require "macrodeck-app"
require "macrodeck-config"

# Load the config file.
puts ">>> Loading configuration."
MD_CFG = MacroDeck::Config.new(File.join(File.dirname(__FILE__), "config", "macrodeck.yml"))

# Start the MacroDeck platform.
puts ">>> Starting MacroDeck Platform on macrodeck-#{MD_CFG.environment}"
MacroDeck::Platform.start!("macrodeck-#{MD_CFG.environment}")
MacroDeck::PlatformDataObjects.define!

puts ">>> MacroDeck Platform started."

# Run our app
run MacroDeck::App

# vim:set ft=ruby
