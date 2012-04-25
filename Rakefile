require "rubygems"

$LOAD_PATH << File.join(File.dirname(__FILE__), ".")
$LOAD_PATH << File.join(File.dirname(__FILE__), "lib")

require "vendor/rturk/init"
require "lib/macrodeck-config"
require "macrodeck-platform/init"

@cfg = MacroDeck::Config.new(File.join(File.dirname(__FILE__), "config", "macrodeck.yml"))
puts ">>> Starting MacroDeck Platform on macrodeck-#{@cfg.environment}"
MacroDeck::Platform.start!("macrodeck-#{@cfg.environment}")
MacroDeck::PlatformDataObjects.define!

Dir.glob("lib/tasks/*.rake").each { |r| import r }
