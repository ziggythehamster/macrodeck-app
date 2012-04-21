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
						puts "- #{tt.id}: #{tt.title}"
						hit = RTurk::Hit.create do |h|
							h.hit_type_id = cfg.turk_hit_type_id
							h.assignments = 2
							h.lifetime = 604800
							h.note = { "item_id" => obj.id, "path" => "/" + tt.id }.to_json
							h.question("#{cfg.base_url}/turk/#{obj.id}")
							h.hit_review_policy("SimplePlurality/2011-09-01", {
								"QuestionIds" => "answer",
								"QuestionAgreementThreshold" => 50, # More than half have to have the same answer to agree
								"DisregardAssignmentIfRejected" => false,
								"ExtendIfHITAgreementScoreIsLessThan" => 100, # The question MUST have an agreed upon answer or we extend
								"ExtendMaximumAssignments" => 10, # At most 10 people have to come to an agreement. Should be more like 3.
								"ExtendMinimumTimeInSeconds" => 86400,
								"ApproveIfWorkerAgreementScoreIsNotLessThan" => 100, # if they get the question right, approve the assignment.
								"RejectIfWorkerAgreementScoreIsLessThan" => 100, # if they didn't get it right, reject the answer.
								"RejectReason" => "Your answer did not agree with the answer of other workers."
							})
						end
						puts hit.inspect
					end
				end
			end
		end
	end
end
