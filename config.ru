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

# Start the MacroDeck platform.
puts "Starting MacroDeck Platform on macrodeck-#{settings.environment}"
MacroDeck::Platform.start!("macrodeck-#{settings.environment}")
MacroDeck::PlatformDataObjects.define!

# Our app
require 'macrodeck-app'
run MacroDeck::App

# vi: set filetype=ruby fileencoding=UTF-8
