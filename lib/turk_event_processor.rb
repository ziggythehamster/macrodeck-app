module MacroDeck
	class TurkEventProcessor
		attr_reader :configuration
		attr_reader :event_type
		attr_reader :event_time
		attr_reader :hit_type
		attr_reader :hit_id
		attr_reader :assignment_id

		# Pass in a hash of parameters.
		def initialize(params)
			@event_type = case params[:event_type]
				when "AssignmentAccepted" then :assignment_accepted
				when "AssignmentAbandoned" then :assignment_abandoned
				when "AssignmentReturned" then :assignment_returned
				when "AssignmentSubmitted" then :assignment_submitted
				when "HITReviewable" then :hit_reviewable
				when "HITExpired" then :hit_expired
				else nil
			end

			@event_time = Time.parse(params[:event_time])
			@hit_type = params[:hit_type]
			@hit_id = params[:hit_id]
			@assignment_id = params[:assignment_id]
			@configuration = params[:configuration]
		end

		# Cause this event to process.
		def process!
			if respond_to? @event_type
				return self.send(@event_type)
			else
				return nil
			end
		end

		private
			# To process when a HIT is reviewable.
			def hit_reviewable
				if !@hit_id.nil?
					# Check which HIT type we're checking for here.
					if @hit_type == @configuration.turk_answer_hit_type_id
						# Look up the HIT
						@hit = RTurk::Hit.find(@hit_id)

						# Mark HIT as reviewing.
						@hit.set_as_reviewing!

						# Parse the JSON stored in annotation
						begin
							annotation = JSON.parse(@hit.annotation)
						rescue JSON::ParserError
							annotation = {}
						end

						# Get answers in need of review.
						@hit.assignments.each do |assignment|
							if !assignment.approved? && !assignment.rejected?
								# Create verification HIT.
								verify_hit = RTurk::Hit.create do |h|
									h.hit_type_id = @configuration.turk_verify_hit_type_id
									h.assignments = 3
									h.lifetime = 604800
									h.note = { "answer_hit_id" => @hit_id, "answer_assignment_id" => @assignment_id }.to_json
									h.question("#{@configuration.base_url}/turk/#{annotation["item_id"]}/verify/#{@hit_id}/")
								end
							end
						end
					elsif @hit_type == @configuration.turk_verify_hit_type_id
						# Look up the HIT
						@hit = RTurk::Hit.find(@hit_id)

						# Mark HIT as reviewing.
						@hit.set_as_reviewing!

						# Parse the annotation
						begin
							annotation = JSON.parse(@hit.annotation)
						rescue JSON::ParserError
							annotation = {}
						end

						# Get the answer HIT
						answer_hit = RTurk::Hit.find(annotation["answer_hit_id"])
						answer_assignment = RTurk::Assignment.new(annotation["answer_assignment_id"])

						# Parse the answer HIT's annotation
						begin
							answer_annotation = JSON.parse(answer_hit.annotation)
						rescue JSON::ParserError
							answer_annotation = {}
						end

						ass_true = []
						ass_false = []

						@hit.assignments.each do |assignment|
							if !assignment.approved? && !assignment.rejected?
								# Is answer true?
								if assignment.answers['validation'].to_i == 1
									ass_true << assignment
								# Is answer false?
								elsif assignment.answers['validation'].to_i == 0
									ass_false << assignment
								end
							end
						end

						# Check for more trues than falses.
						if ass_true.length > ass_false.length
							# Approve original assignment.
							answer_assignment.approve!("Your answer was verified correct by other workers.")

							# Accept true answers.
							ass_true.each do |a|
								a.approve!("Majority of workers agreed with your answer.")
							end

							# Reject false answers.
							ass_false.each do |a|
								a.reject!("Majority of workers disagreed with your answer.")
							end

							@hit.dispose!
							answer_hit.dispose!

							path_components = answer_annotation["path"].split("/")[1..-1]
							resp_key = path_components.last
							item = ::DataObject.get(answer_annotation["item_id"])
							item.turk_responses ||= {}

							# Look up the turk task and if there are prerequisites, properly
							# set the root of the tree to the prerequisite values.
							root = item.turk_responses
							path_components[0..-2].each do |p|
								if p.include?("=")
									root = root[p]
								else
									root = root["#{p}="]
								end
							end

							# Is answer an array?
							if answer_assignment.answers.key?("answer[]")
								root[resp_key] = answer_assignment.answers["answer[]"].split("|")
								root[resp_key].each do |resp_val|
									root["#{resp_key}=#{resp_val}"] = {}
								end
							else
								root[resp_key] = answer_assignment.answers["answer"]
								root["#{resp_key}="] = {}
							end

							# Save item.
							item.save

							# TODO: Create new answer HIT.
							# Does this answer have a parent? (path length != 1)
							# Yes -> Is parent an array?
							#        Yes -> Iterate array, check if each value is answered. Answered?
							#               Yes -> Skip. If all skipped, proceed to creating HIT that is a
							#                      child of this answer.
							#               No  -> Create HIT (will be a sibling of this answer), exit loop
							#        No  -> Create a HIT that is a child of this answer, taking into account if
							#               this answer is an array.
							# No  -> Create a HIT that is a child of this answer, taking into account if this
							#        answer is an array.

							# Check if this answer has a parent
							if path_components.length == 1
								# It doesn't, is this answer an array?
								if answer_assignment.answers.key?("answer[]")
									# Get next task (this is an array).
									item.class.turk_tasks.each do |tt|
										resp = { resp_key => [ item.turk_responses[resp_key].first ] }
										path = "/#{resp_key}=#{item.turk_responses[resp_key].first}/#{tt.id}"

										if tt.prerequisites_met?(resp) && !tt.answered?(resp)
											self.create_hit({
												"item_id" => item.id,
												"path" => path,
												"multiple_answer" => tt.field["type"].is_a?(Array)
											})
										end
									end
								else
									# Get next task (this is not an array).
									item.class.turk_tasks.each do |tt|
										if tt.prerequisites_met?(item.turk_responses) && !tt.answered?(item.turk_responses)
											path = "/#{resp_key}/#{tt.id}"
											self.create_hit({
												"item_id" => item.id,
												"path" => path,
												"multiple_answer" => tt.field["type"].is_a?(Array)
											})
										end
									end
								end
							else
								# Parent an array? (Check path up until second-to-last component
								# to see if it has an =)
								if path_components[-2].include?("=")
									# Parent is an array
									parent = item.turk_responses # which is wrong, we will eventually have a valid parent.
									# -3 is intentional.
									path_components[0..-3].each do |p|
										if p.include?("=")
											parent = parent[p]
										else
											parent = parent["#{p}="]
										end
									end
									# here's where we do -2
									parent_answers = parent[path_components[-2].split("=")[0]]

									make_child = true

									# Now, let's iterate the answers.
									parent_answers.each do |answer|
										# Check if answered
										if !parent.key?("#{path_components[-2].split("=")[0]}=#{answer}") && !parent["#{path_components[-2].split("=")[0]}=#{answer}"].key?(resp_key)
											make_child = false

											path = "/#{path_components[0..-3].join("/")}/#{path_components[-2].split("=")[0]}=#{answer}/#{resp_key}")

											self.create_hit({
												"item_id" => item.id,
												"path" => path,
												"multiple_answer" => item.class.turk_task_by_id(path_components[-2].split("=")[0]).field["type"].is_a?(Array)
											})

											break
										end
									end

									# Make the child if needed.
									if make_child
										item.class.turk_tasks.each do |tt|
											if tt.prerequisites_met?(item.turk_responses) && !tt.answered?(item.turk_responses)
												path = "/#{path_components.join("/")}/#{tt.id}"

												self.create_hit({
													"item_id" => item.id,
													"path" => path,
													"multiple_answer" => tt.field["type"].is_a?(Array)
												})
											end
										end
									end
								else
									# Parent is not an array
									item.class.turk_tasks.each do |tt|
										if tt.prerequisites_met?(item.turk_responses) !tt.answered?(item.turk_responses)
											path = "#{answer_annotation["path"]}/#{tt.id}"
											self.create_hit({
												"item_id" => item.id,
												"path" => path,
												"multiple_answer" => tt.field["type"].is_a?(Array)
											})
										end
									end
								end
							end
						else
							# Reject original assignment.
							answer_assignment.reject!("Your answer was verified as incorrect by other workers.")

							# Reject true answers.
							ass_true.each do |a|
								a.reject!("Majority of workers disagreed with your answer.")
							end

							# Accept false answers.
							ass_false.each do |a|
								a.approve!("Majority of workers agreed with your answer.")
							end

							# Extend the original HIT and dispose of this HIT to allow another answer.
							@hit.dispose!
							answer_hit.extend!(:assignments => 1, :seconds => 604800)
						end
					else
						puts "HIT Type ID #{@hit_type} not one of the configured HIT Types!"
						return false
					end
				end
			end

			# Common method that creates a HIT during processing.
			# Not meant to be called directly.
			# params accepted:
			# item_id, path, multiple_answer
			def create_hit(params = {})
				hit = RTurk::Hit.create do |h|
					h.hit_type_id = @configuration.turk_answer_hit_type_id
					h.assignments = 1
					h.lifetime = 604800
					h.note = { "item_id" => params["item_id"], "path" => params["path"], "multiple_answer" => params["multiple_answer"] }.to_json
					h.question("#{@configuration.base_url}/turk/#{params["item_id"]}")
				end
				return hit
			end
	end
end
