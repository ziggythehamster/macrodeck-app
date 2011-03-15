module MacroDeck
	# Renders a description as a paragraph
	class DescriptionBehavior < Behavior
		def to_html
			"<p>#{Rack::Utils.escape_html(@data_object.description)}</p>"
		end
	end
end
