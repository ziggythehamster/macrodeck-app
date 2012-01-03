$LOAD_PATH << File.join(File.dirname(__FILE__), "..")

gem "rturk"
require "rturk"
require "lib/macrodeck-config"
require "macrodeck-platform/init"

cfg = MacroDeck::Config.new(File.join(File.dirname(__FILE__), "..", "..", "config", "macrodeck.yml"))

puts ">>> Starting MacroDeck Platform on macrodeck-#{cfg.environment}"
MacroDeck::Platform.start!("macrodeck-#{cfg.environment}")
MacroDeck::PlatformDataObjects.define!

namespace :macrodeck do
	namespace :mturk do
		desc "Creates pending HITs"
		task :create_hits do
			SpecialPhoto.view("by_turk_unanswered", :reduce => false, :include_docs => true).each do |obj|
				puts "#{obj.id}:"
				obj.pending_turk_tasks.each do |tt|
					if tt.prerequisites.length == 0
						puts "- #{tt.title}"
						hit = RTurk::Hit.create do |h|
							h.hit_type_id = cfg.turk_answer_hit_type_id
							h.assignments = 1
							h.lifetime = 604800
							h.note = { "item_id" => obj.id }.to_json
							h.question("#{cfg.base_url}/turk/#{obj.id}/")
						end
						puts hit.inspect
					end
				end
			end
		end
	end
end
