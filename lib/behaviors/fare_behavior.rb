module MacroDeck
	# Renders a list of fares as a list of items, concatenated by commas.
	class FareBehavior < Behavior
		def to_html
			Rack::Utils.escape_html(@data_object.fare.join(", "))
		end
	end
end
