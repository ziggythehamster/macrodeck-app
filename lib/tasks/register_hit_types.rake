gem "rturk"
require "rturk"
require "lib/macrodeck-config"

cfg = MacroDeck::Config.new(File.join(File.dirname(__FILE__), "..", "..", "config", "macrodeck.yml"))

namespace :macrodeck do
	namespace :mturk do
		desc "Creates HIT types for the app."
		task :register_hit_types do
			ans = RTurk::RegisterHITType(:title => "Answer a Question", :description => "You must answer a single question.", :reward => cfg.turk_reward, :currency => "USD")
			puts "Answer a Question HIT Type: #{ans.type_id}"
		end
	end
end
