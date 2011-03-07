module MacroDeck
	# Renders a title as a heading.
	class TitleBehavior < Behavior
		def to_html
			"<h2>#{@value}</h2>"
		end
	end
end
