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
									h.assignments = 1
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

							resp_key = answer_annotation["turk_question"]
							item = ::DataObject.get(answer_annotation["item_id"])
							item.turk_responses ||= {}

							# TODO: Look up the turk task and if there are prerequisites, properly
							# set the root of the tree to the prerequisite values.

							# Is answer an array?
							if answer_assignment.answers.key?("answer[]")
								item.turk_responses[resp_key] = answer_assignment.answers["answer[]"].split("|")
								item.turk_responses[resp_key].each do |resp_val|
									item.turk_responses["#{resp_key}=#{resp_val}"] = {}
								end
							else
								item.turk_responses[resp_key] = answer_assignment.answers["answer"]
								item.turk_responses["#{resp_key}="] = {}
							end

							# Save item.
							item.save
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
	end
end
