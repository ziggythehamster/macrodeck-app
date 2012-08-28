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
				when "Ping" then :ping
				else nil
			end

			@event_time = Time.parse(params[:event_time])
			@hit_type = params[:hit_type]
			@hit_id = params[:hit_id]
			@assignment_id = params[:assignment_id]
			@configuration = params[:configuration]

			@hits_created = 0
		end

		# Cause this event to process.
		def process!
			puts "[MacroDeck::TurkEventProcessor] Processing requested. Event type = #{@event_type.to_s}"

			if self.private_methods.include? @event_type.to_s
				return self.send(@event_type.to_sym)
			else
				puts "[MacroDeck::TurkEventProcessor] Processor doesn't support event type :("
				return nil
			end
		end

		private
			# To process an AssignmentAccepted event.
			def assignment_accepted
				if !@hit_id.nil? && !@assignment_id.nil?
					puts "[MacroDeck::TurkEventProcessor] AssignmentAccepted"

					# Look up the HIT
					@hit = RTurk::Hit.find(@hit_id)

					# Parse the JSON stored in annotation
					begin
						annotation = JSON.parse(@hit.annotation)
					rescue JSON::ParserError
						annotation = {}
					end

					retries = 0

					begin
						# Get the item we're operating on.
						item = ::DataObject.get(annotation["item_id"])
						item.turk_events ||= {}
						item.turk_events["assignment_accepted"] ||= {}

						# Check if we have already worked on this item.
						if !item.turk_events["assignment_accepted"][@assignment_id].nil?
							puts "[MacroDeck::TurkEventProcessor] Not processing - event already processed for Assignment ID #{@assignment_id}"
							return
						end

						# Mark event as processed.
						item.turk_events["assignment_accepted"][@assignment_id] = Time.new.getutc.iso8601
						item.save
					rescue RestClient::Conflict
						# We had a conflict when saving the item. Let's retry until we are able to save without a conflict.
						# This could cause an infinite loop, so we don't retry after a certain number of retries.

						if retries < 10
							retries += 1
							puts "[MacroDeck::TurkEventProcessor] 409 Conflict while saving - retry #{retries}"
							retry
						else
							puts "[MacroDeck::TurkEventProcessor] 409 Conflict while saving - giving up"
						end
					end
				end
			end

			# To process an AssignmentSubmitted event.
			def assignment_submitted
				if !@hit_id.nil? && !@assignment_id.nil?
					puts "[MacroDeck::TurkEventProcessor] AssignmentSubmitted"

					# Look up the HIT
					@hit = RTurk::Hit.find(@hit_id)

					# Parse the JSON stored in annotation
					begin
						annotation = JSON.parse(@hit.annotation)
					rescue JSON::ParserError
						annotation = {}
					end

					retries = 0

					begin
						# Get the item we're operating on.
						item = ::DataObject.get(annotation["item_id"])
						item.turk_events ||= {}
						item.turk_events["assignment_submitted"] ||= {}

						# Check if we have already worked on this item.
						if !item.turk_events["assignment_submitted"][@assignment_id].nil?
							puts "[MacroDeck::TurkEventProcessor] Not processing - event already processed for Assignment ID #{@assignment_id}"
							return
						end

						# Mark event as processed.
						item.turk_events["assignment_submitted"][@assignment_id] = Time.new.getutc.iso8601
						item.save
					rescue RestClient::Conflict
						# We had a conflict. See assignment accepted for explanation.

						if retries < 10
							retries += 1
							puts "[MacroDeck::TurkEventProcessor] 409 Conflict while saving - retry #{retries}"
							retry
						else
							puts "[MacroDeck::TurkEventProcessor] 409 Conflict while saving - giving up"
						end
					end
				end
			end

			# To process a Ping event.
			def ping
				puts "[MacroDeck::TurkEventProcessor] Ping"
			end

			# To process when a HIT is reviewable.
			def hit_reviewable
				if !@hit_id.nil?
					puts "[MacroDeck::TurkEventProcessor] HITReviewable"

					# Look up the HIT
					@hit = RTurk::Hit.find(@hit_id)
					@hit_review_results = RTurk::GetReviewResultsForHIT(:hit_id => @hit_id)

					# Check that we have all the assignments submitted.
					if @hit.max_assignments != @hit.assignments.length
						puts "[MacroDeck::TurkEventProcessor] Not processing - expected HIT to have #{@hit.max_assignments} assignments, but only had #{@hit.assignments.length}"
						return
					end

					# Mark HIT as reviewing.
					@hit.set_as_reviewing! if @hit.status == "Reviewable"

					# Parse the JSON stored in annotation
					begin
						annotation = JSON.parse(@hit.annotation)
					rescue JSON::ParserError
						annotation = {}
					end

					# Get assignment IDs that have the correct answer and those that don't.
					correct_assignments = []
					incorrect_assignments = []
					the_answer = nil

					puts "[MacroDeck::TurkEventProcessor] Checking worker agreement score..."

					@hit_review_results.hit_review_report.each do |report|
						if report[:type] == "result" && report[:key] == "WorkerAgreementScore"
							if report[:value].to_i == 100
								correct_assignments << report[:subject_id]
							else
								incorrect_assignments << report[:subject_id]
							end
						end
					end

					puts "[MacroDeck::TurkEventProcessor] Approving/rejecting assignments..."

					# Loop through HIT assignments and approve/deny as needed.
					# Also get the plurality answer.
					@hit.assignments.each do |assignment|
						if correct_assignments.include?(assignment.id)
							if the_answer.nil?
								puts "[MacroDeck::TurkEventProcessor] Answer currently unknown - getting answer from assignment ID #{assignment.id}"

								if assignment.answers.key?("answer[]")
									the_answer = assignment.answers["answer[]"].split("|")
								else
									the_answer = assignment.answers["answer"]
								end
							end
							assignment.approve!("The majority of workers agreed with your answer.") if assignment.status == "Submitted"

							puts "[MacroDeck::TurkEventProcessor] Approved assignment ID #{assignment.id}"
						elsif incorrect_assignments.include?(assignment.id)
							assignment.reject!("The majority of workers disagreed with your answer.") if assignment.status == "Submitted"
							puts "[MacroDeck::TurkEventProcessor] Rejected assignment ID #{assignment.id}"
						else
							puts "[MacroDeck::TurkEventProcessor] *** Assignment ID #{assignment.id} is neither correct nor incorrect."
						end
					end

					# Get the path components and response key.
					path_components = annotation["path"].split("/")[1..-1]
					resp_key = path_components.last

					puts "[MacroDeck::TurkEventProcessor] Saving response..."
					puts "[MacroDeck::TurkEventProcessor] Path=#{annotation["path"]} Answer=#{the_answer.inspect}"

					retries = 0

					# Wrap the saving part in a begin/end so that we can trap conflicts.
					begin
						# Get the item we're operating on.
						item = ::DataObject.get(annotation["item_id"])
						item.turk_responses ||= {}
						item.turk_events ||= {}
						item.turk_events["hit_reviewable"] ||= {}

						# Check if we have already worked on this item.
						if !item.turk_events["hit_reviewable"][@hit_id].nil?
							puts "[MacroDeck::TurkEventProcessor] Not processing - event already processed for HIT ID #{@hit_id}"
							return
						end

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
						if the_answer.is_a?(Array)
							root[resp_key] = the_answer
							root[resp_key].each do |resp_val|
								root["#{resp_key}=#{resp_val}"] = {}
							end
						else
							root[resp_key] = the_answer
							root["#{resp_key}="] = {}
						end

						# Mark event as processed.
						item.turk_events["hit_reviewable"][@hit_id] = Time.new.getutc.iso8601

						# Save item.
						item.save
					rescue RestClient::Conflict => ex
						# We had a conflict. See assignment accepted for explanation.

						if retries < 10
							retries += 1
							puts "[MacroDeck::TurkEventProcessor] 409 Conflict while saving - retry #{retries}"
							retry
						else
							puts "[MacroDeck::TurkEventProcessor] 409 Conflict while saving - giving up and dying horribly"
							raise ex
						end
					end

					# Get a response tree.
					response_tree = MacroDeck::TurkResponseTree::Tree.new(item)

					puts "[MacroDeck::TurkEventProcessor] Creating new answer HIT..."
					puts "[MacroDeck::TurkEventProcessor] Response Key = #{resp_key}"

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
						puts "[MacroDeck::TurkEventProcessor] Answer does not have a parent."

						# It doesn't, is this answer an array?
						if the_answer.is_a?(Array)
							puts "[MacroDeck::TurkEventProcessor] Answer with no parent is an array."

							# Iterate the answers array. This is because we might be branching off into
							# multiple trees.
							the_answer.each do |answer|
								puts "[MacroDeck::TurkEventProcessor] Checking answer item: #{answer.inspect}"

								# Get next task (this is an array).
								item.class.turk_tasks.each do |tt|
									if tt.id == resp_key
										puts "[MacroDeck::TurkEventProcessor] Not checking #{tt.id} because it is the task we're currently processing and that would be stupid."
									else
										puts "[MacroDeck::TurkEventProcessor] Checking if #{tt.id} is answerable..."

										resp = { resp_key => [ answer ] }
										path = "/#{resp_key}=#{answer}/#{tt.id}"

										if tt.prerequisites_met?(resp) && !tt.answered?(resp)
											create_hit({
												"item_id" => item.id,
												"path" => path
											})
										else
											# Print out some debugging information so we can figure out why a task isn't answerable

											puts "[MacroDeck::TurkEventProcessor] #{tt.id} is not answerable."

											if tt.prerequisites_met?(resp)
												puts "[MacroDeck::TurkEventProcessor] #{tt.id} prerequisites met? Yes."
											else
												puts "[MacroDeck::TurkEventProcessor] #{tt.id} prerequisites met? No."
											end

											if tt.answered?(resp)
												puts "[MacroDeck::TurkEventProcessor] #{tt.id} answered? Yes."
											else
												puts "[MacroDeck::TurkEventProcessor] #{tt.id} answered? No."
											end
										end
									end
								end
							end
						else
							puts "[MacroDeck::TurkEventProcessor] Answer with no parent is not an array."

							# Get next task (this is not an array).
							item.class.turk_tasks.each do |tt|
								if tt.id == resp_key
									puts "[MacroDeck::TurkEventProcessor] Not checking #{tt.id} because it is the task we're currently processing and that would be stupid."
								else
									puts "[MacroDeck::TurkEventProcessor] Checking if #{tt.id} is answerable..."

									if tt.prerequisites_met?(item.turk_responses) && !tt.answered?(item.turk_responses)
										path = "/#{resp_key}/#{tt.id}"
										create_hit({
											"item_id" => item.id,
											"path" => path
										})
									end
								end
							end
						end
					else
						puts "[MacroDeck::TurkEventProcessor] Answer has a parent."

						# Parent an array? (Check path up until second-to-last component
						# to see if it has an =)
						if path_components[-2].include?("=")
							puts "[MacroDeck::TurkEventProcessor] Answer has a parent and it is an array."

							# Parent is an array
							# First we want the path leading up to the parent because we are
							# converting Task_Whatever=X to Task_Whatever. So this is length
							# minus three because length is 1-based and that it's two from the end
							# (parent + current)

							# Check if length minus 3 is less than 0 - this means the parent path starts as /.
							if path_components.length - 3 < 0
								parent_path = "/"
							else
								parent_path = "/"
								parent_path << path_components[0..(path_components.length - 3)].join("/")
							end

							# Append the parent minus the value.
							parent_key = path_components[path_components.length - 3].split("=")[0]
							parent_path << parent_key

							puts "[MacroDeck::TurkEventProcessor] Parent path = #{parent_path}"
							parent_answers = response_tree.value_at_path(parent_path)

							make_child = true

							# Now, let's iterate the answers. This is where we create siblings.
							parent_answers.each do |answer|
								puts "[MacroDeck::TurkEventProcessor] Checking if answer #{answer} is answered..."

								# Check if answered
								begin
									sibling_result = response_tree.at_path("#{parent_path}=#{answer}")
									if !sibling_result.key?(resp_key)
										puts "[MacroDeck::TurkEventProcessor] Nope! (Chuck Testa.)"

										make_child = false

										path = "/#{path_components[0..-3].join("/")}/#{parent_key}=#{answer}/#{resp_key}"

										create_hit({
											"item_id" => item.id,
											"path" => path
										})

										break
									end
								rescue MacroDeck::TurkResponseTree::InvalidPathError
									puts "[MacroDeck::TurkEventProcessor] Path #{parent_path}=#{answer} invalid!"
								end
							end

							# Make the child if needed.
							if make_child
								puts "[MacroDeck::TurkEventProcessor] All answers answered - possibly making child."

								item.class.turk_tasks.each do |tt|
									if path_components.join("/").include?(tt.id)
										puts "[MacroDeck::TurkEventProcessor] Not checking #{tt.id} because it is already in our path, so we either answered it or are answering it."
									elsif !tt.prerequisites.include?(resp_key)
										puts "[MacroDeck::TurkEventProcessor] Not checking #{tt.id} because it doesn't have #{resp_key} as a prerequisite."
									else
										puts "[MacroDeck::TurkEventProcessor] Checking if #{tt.id} is answered..."

										if tt.prerequisites_met?(item.turk_responses) && !tt.answered?(item.turk_responses)
											path = "/#{path_components.join("/")}/#{tt.id}"

											create_hit({
												"item_id" => item.id,
												"path" => path
											})
										end
									end
								end
							end
						else
							puts "[MacroDeck::TurkEventProcessor] Answer with parent is not an array."

							# Parent is not an array
							item.class.turk_tasks.each do |tt|
								if path_components.join("/").include?(tt.id)
									puts "[MacroDeck::TurkEventProcessor] Not checking #{tt.id} because it is already in our path, so we either answered it or are answering it."
								elsif !tt.prerequisites.include?(resp_key)
									puts "[MacroDeck::TurkEventProcessor] Not checking #{tt.id} because it doesn't have #{resp_key} as a prerequisite."
								else
									puts "[MacroDeck::TurkEventProcessor] Checking if #{tt.id} is answered..."
									if tt.prerequisites_met?(item.turk_responses) && !tt.answered?(item.turk_responses)
										path = "#{annotation["path"]}/#{tt.id}"
										create_hit({
											"item_id" => item.id,
											"path" => path
										})
									end
								end
							end
						end
					end

					# Check if we are completely done processing this.
					puts "[MacroDeck::TurkEventProcessor] Checking if we are finished processing..."

					if @hits_created == 0
						are_we_done_yet = true

						# Loop through turk tasks. find a path that has that turk task? good! otherwise bad.
						item.class.turk_tasks.each do |tt|
							puts "[MacroDeck::TurkEventProcessor] Looking for #{tt.id}..."
							found_a_match = false

							response_tree.all_paths.each do |path|
								if path.include?(tt.id)
									puts "[MacroDeck::TurkEventProcessor] #{tt.id} found in #{path}!"
									found_a_match = true
									break
								end
							end

							# If we did not find a match, we are not done yet, so stop processing at this point.
							unless found_a_match
								puts "[MacroDeck::TurkEventProcessor] Did not find a match, we're not done :("
								are_we_done_yet = false
								break
							end
						end

						# are_we_done_yet should be true if we're going to the showcase showdown.
						if are_we_done_yet
							puts "[MacroDeck::TurkEventProcessor] Time for the showcase showdown!"
							# TODO.
						end
					end
				end
			end

			# Common method that creates a HIT during processing.
			# Not meant to be called directly.
			# params accepted:
			# item_id, path, multiple_answer
			def create_hit(params = {})
				puts "[MacroDeck::TurkEventProcessor] Creating HIT. ItemID=#{params["item_id"]} Path=#{params["path"]}"

				hit = RTurk::Hit.create do |h|
					h.hit_type_id = @configuration.turk_hit_type_id
					h.assignments = 2
					h.lifetime = 604800
					h.note = { "item_id" => params["item_id"], "path" => params["path"] }.to_json
					h.question("#{@configuration.base_url}/turk/#{params["item_id"]}")
					h.hit_review_policy("SimplePlurality/2011-09-01", @configuration.hit_review_policy_defaults)
				end

				@hits_created += 1
				return hit
			end
	end
end
