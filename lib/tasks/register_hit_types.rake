gem "rturk"
require "rturk"
require "lib/macrodeck-config"

cfg = MacroDeck::Config.new(File.join(File.dirname(__FILE__), "..", "..", "config", "macrodeck.yml"))

namespace :macrodeck do
	namespace :mturk do
		desc "Creates HIT types for the app."
		task :register_hit_types do
			ans = RTurk::RegisterHITType(:title => "Answer a Question", :description => "You must answer a single question.", :reward => 0.25, :currency => "USD")
			vfy = RTurk::RegisterHITType(:title => "Verify an Answer", :description => "Verify another worker's answer to a question.", :reward => 0.25, :currency => "USD")
			puts "Answer a Question HIT Type: #{ans["HITTypeId"]}"
			puts "Verify an Answer HIT Type: #{vfy["HITTypeId"]}"
		end
	end
end
