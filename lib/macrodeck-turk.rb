# The core of the MacroDeck application.
# Need a way to handle extensions and allow extending this base app with more stuff.

# Gems used by this lib.
gem "activesupport"
gem "uuidtools"

# Things to require.
require 'sinatra/base'
require 'active_support' # For the inflector.
require 'uuidtools'
require 'erb'
require "turk_signer"
require "turk_event_processor"

module MacroDeck
	class Turk < Sinatra::Base
		cattr_accessor :configuration

		use Rack::MethodOverride # Allow browsers to use a RESTful API

		helpers do
			include Rack::Utils
			alias_method :h, :escape_html
		end

		get '/notification_receptor' do
			# Validate Signature parameter.
			correct_signature = TurkSigner.sign(self.configuration.aws_secret_access_key, "AWSMechanicalTurkRequesterNotification", "Notify", params["Timestamp"])

			if params["Signature"] != correct_signature
				puts "[MTurk Notification Receptor] SIGNATURE MISMATCH. EXPECTED #{correct_signature}, GOT #{params["Signature"]}. Returning 403 Forbidden to client."
				halt 403
			end

			# Check if first event is present.
			if params["Event.1.EventType"]
				event_id = 1
				events_to_process = true
			else
				puts "[MTurk Notification Receptor] No events to process."
				events_to_process = false
			end

			# Loop through the events
			while events_to_process
				event_type = params["Event.#{event_id}.EventType"]
				event_time = params["Event.#{event_id}.EventTime"]
				hit_type = params["Event.#{event_id}.HITTypeId"]
				hit_id = params["Event.#{event_id}.HITId"]
				assignment_id = params["Event.#{event_id}.AssignmentId"]

				puts "[MTurk Notification Receptor] Processing event type #{event_type} for HIT ID #{hit_id}..."
				processor = MacroDeck::TurkEventProcessor.new({
					:event_type => event_type,
					:event_time => event_time,
					:hit_type => hit_type,
					:hit_id => hit_id,
					:assignment_id => assignment_id,
					:configuration => self.configuration
				})
				processor.process!

				if params["Event.#{event_id + 1}.EventType"]
					event_id = event_id + 1
				else
					puts "[MTurk Notification Receptor] No more events to process."
					events_to_process = false
				end
			end
		end

		# Render a question for the requested ID.
		get '/:id/?' do
			obj = ::DataObject.get(params[:id])

			if obj.class.respond_to?(:turk_tasks) && !obj.class.turk_tasks.nil? && obj.class.turk_tasks.length > 0
				# Render the question
				task = nil
				answers = obj.turk_responses
				obj.class.turk_tasks.each do |tt|
					task = tt if task.nil? && tt.prerequisites_met?(answers) && !tt.answered?(answers)
				end
				erb :"turk_question.html", :layout => self.configuration.layout.to_sym, :locals => { :task => task, :item => obj, :assignment_id => params[:assignmentId] }
			else
				erb :"turk_no_questions.html", :layout => self.configuration.layout.to_sym
			end
		end
	end
end
