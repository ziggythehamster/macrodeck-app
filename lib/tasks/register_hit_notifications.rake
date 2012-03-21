gem "rturk"
require "rturk"
require "lib/macrodeck-config"

cfg = MacroDeck::Config.new(File.join(File.dirname(__FILE__), "..", "..", "config", "macrodeck.yml"))

namespace :macrodeck do
	namespace :mturk do
		desc "Registers for notifications for both HIT types"
		task :register_hit_notifications do
			# Build the notification structure.
			notification = RTurk::Notification.new
			notification.transport = 'REST'
			notification.destination = "#{cfg.base_url}/turk/notification_receptor"
			notification.event_type = %w{AssignmentAccepted AssignmentAbandoned AssignmentReturned AssignmentSubmitted HITReviewable HITExpired}

			RTurk::SetHITTypeNotification(:hit_type_id => cfg.turk_answer_hit_type_id, :notification => notification, :active => true)
			RTurk::SetHITTypeNotification(:hit_type_id => cfg.turk_verify_hit_type_id, :notification => notification, :active => true)
		end
	end
end
