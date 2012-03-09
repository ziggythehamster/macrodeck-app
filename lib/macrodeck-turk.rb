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

module MacroDeck
	class Turk < Sinatra::Base
		cattr_accessor :configuration

		use Rack::MethodOverride # Allow browsers to use a RESTful API

		helpers do
			include Rack::Utils
			alias_method :h, :escape_html
		end

		get '/notification_receptor' do
			# TODO: Validate Signature parameter.

			# Check if first event is present.
			if params["Event.1.EventType"]
				event_id = 1
				events_to_process = true
			else
				events_to_process = false
			end

			# Loop through the events
			while events_to_process
				event_type = params["Event.#{event_id}.EventType"]
				event_time = params["Event.#{event_id}.EventTime"]
				hit_type = params["Event.#{event_id}.HITTypeId"]
				hit_id = params["Event.#{event_id}.HITId"],
				assignment_id = params["Event.#{event_id}.AssignmentId"]

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
				erb :"turk_question.html", :layout => self.configuration.layout.to_sym, :locals => { :task => task, :item => obj }
			else
				erb :"turk_no_questions.html", :layout => self.configuration.layout.to_sym
			end
		end

		# Render verification for a question.
		get '/:id/verify/:answer_hit_id/?' do
			obj = ::DataObject.get(params[:id])

			if obj.class.respond_to?(:turk_tasks) && !obj.class.turk_tasks.nil? && obj.class.turk_tasks.length > 0
				# TODO:
				# Get the active turk task / question.

				# Get the HIT that we're currently working on.
				hit = RTurk::Hit.find(params[:hitId])
				begin
					hit_annotation = JSON.parse(hit.annotation)
				rescue
					hit_annotation = {}
				end

				# Get the answer HIT.
				answer_hit = RTurk::Hit.find(params[:answer_hit_id])
				begin
					answer_annotation = JSON.parse(answer_hit.annotation)
				rescue
					answer_annotation = {}
				end

				# Get the answer assignment from the HIT we're currently working on.
				answer_assignment = answer_hit.assignments.select do |assignment|
					assignment.id == hit_annotation["answer_assignment_id"]
				end.first

				# Get the answer from the HIT.

				# Present user with a form to agree or disagree.
				# Submit back to MTurk
			else
				erb :"turk_no_questions.html", :layout => self.configuration.layout.to_sym
			end
		end
	end
end
