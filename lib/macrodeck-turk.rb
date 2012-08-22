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
require "turk_response_tree"

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
			hit_id = params[:hitId]
			assignment_id = params[:assignmentId]
			hit = RTurk::Hit.find(hit_id)

			# Get the HIT's annotation
			begin
				annotation = JSON.parse(hit.annotation)
			rescue JSON::ParserError
				annotation = {}
			end

			puts "HIT Path: #{annotation["path"]}"

			path_components = annotation["path"].split("/")[1..-1]

			if obj.class.respond_to?(:turk_tasks) && !obj.class.turk_tasks.nil? && obj.class.turk_tasks.length > 0
				# Render the question
				task = nil
				answers = obj.turk_responses
				answer_tree = MacroDeck::TurkResponseTree::Tree.new(obj)

				if path_components[-1].include?("=")
					task = obj.class.turk_task_by_id(path_components[-1].split("=")[0])
				else
					task = obj.class.turk_task_by_id(path_components[-1])
				end

				# Map turk fields to values, if possible.
				value_map = {}

				path_components.each_index do |idx|
					# If the path component contains an =, we have the value and needn't look it up.
					if path_components[idx].include?("=")
						tt = obj.class.turk_task_by_id(path_components[idx].split("=")[0])
						if tt
							if tt.field["type"].is_a?(Array)
								type = tt.field["type"][0]
							else
								type = tt.field["type"]
							end

							if type.include?("#")
								begin
									value_map[tt.field["name"]] = [type.split("#")[1], path_components[idx].split("=")[1]]
								rescue MacroDeck::TurkResponseTree::InvalidPathError
									value_map[tt.field["name"]] = nil
								end
							else
								begin
									value_map[tt.field["name"]] = [type, path_components[idx].split("=")[1]]
								rescue MacroDeck::TurkResponseTree::InvalidPathError
									value_map[tt.field["name"]] = nil
								end
							end
						else
							raise "Turk task lookup failed!"
						end
					else
						tt = obj.class.turk_task_by_id(path_components[idx])

						if tt
							if tt.field["type"].is_a?(Array)
								type = tt.field["type"][0]
							else
								type = tt.field["type"]
							end

							if tt.field["type"].include?("#")
								begin
									value_map[tt.field["name"]] = [type.split("#")[1], answer_tree.value_at_path(path_components[0..idx].join("/"))]
								rescue MacroDeck::TurkResponseTree::InvalidPathError
									value_map[tt.field["name"]] = nil
								end
							else
								begin
									value_map[tt.field["name"]] = [type, answer_tree.value_at_path(path_components[0..idx].join("/"))]
								rescue MacroDeck::TurkResponseTree::InvalidPathError
									value_map[tt.field["name"]] = nil
								end
							end
						else
							raise "Turk task lookup failed!"
						end
					end
				end

				puts "Rendering question form for #{task.id}. Behavior: #{task.field_behavior}"

				erb :"turk_question.html", :layout => self.configuration.layout.to_sym, :locals => { :task => task, :item => obj, :assignment_id => params[:assignmentId], :value_map => value_map }
			else
				erb :"turk_no_questions.html", :layout => self.configuration.layout.to_sym
			end
		end
	end
end
