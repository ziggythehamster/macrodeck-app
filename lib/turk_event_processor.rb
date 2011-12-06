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
									h.note = { "item_id" => annotation["item_id"], "answer_hit_id" => @hit_id, "answer_assignment_id" => @assignment_id }.to_json
									# TODO: set question up
								end
							end
						end
					elsif @hit_type == @configuration.turk_verify_hit_type_id
						# Look up the HIT
						@hit = RTurk::Hit.find(@hit_id)

						# Get number of true answers.
						# Get number of false answers.
						# If true_count > false_count:
						# 	Accept original assignment.
						# 	Accept true answers.
						# 	Reject false answers.
						# 	Save the answer to the object.
						# If false_count > true_count:
						# 	Reject original assignment.
						# 	Reject true answers.
						# 	Accept false answers.
						# 	Extend the original HIT to allow another answer.
					else
						puts "HIT Type ID #{@hit_type} not one of the configured HIT Types!"
						return false
					end
				end
			end
	end
end
