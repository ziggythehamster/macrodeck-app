module MacroDeck
	# Renders a description as a paragraph
	class DescriptionBehavior < Behavior
		def to_html
			"<p>#{@data_object.description}</p>"
		end
	end
end
