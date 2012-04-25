namespace :macrodeck do
	namespace :mturk do
		desc "Creates HIT types for the app."
		task :register_hit_types do
			ans = RTurk::RegisterHITType(:title => "Answer a Question", :description => "You must answer a single question.", :reward => @cfg.turk_reward, :currency => "USD")
			puts "Answer a Question HIT Type: #{ans.type_id}"
		end
	end
end
