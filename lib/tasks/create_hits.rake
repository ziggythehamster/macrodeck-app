namespace :macrodeck do
	namespace :mturk do
		desc "Creates pending HITs"
		task :create_hits do
			SpecialPhoto.view("by_turk_unanswered", :reduce => false, :include_docs => true).each do |obj|
				puts "#{obj.id}:"
				obj.pending_turk_tasks.each do |tt|
					if tt.prerequisites.length == 0
						puts "- #{tt.id}: #{tt.title}"
						hit = RTurk::Hit.create do |h|
							h.hit_type_id = @cfg.turk_hit_type_id
							h.assignments = 2
							h.lifetime = 604800
							h.note = { "item_id" => obj.id, "path" => "/" + tt.id }.to_json
							h.question("#{@cfg.base_url}/turk/#{obj.id}")
							h.hit_review_policy("SimplePlurality/2011-09-01", @cfg.hit_review_policy_defaults)
						end
						puts hit.inspect
					end
				end
			end
		end
	end
end
