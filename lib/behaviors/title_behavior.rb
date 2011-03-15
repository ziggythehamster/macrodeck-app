module MacroDeck
	# Renders a title as a heading.
	class TitleBehavior < Behavior
		def to_html
			if @data_object[:abbreviation]
				return "<h2>#{Rack::Utils.escape_html(@data_object.title)} (#{Rack::Utils.escape_html(@data_object.abbreviation)})</h2>"
			else
				return "<h2>#{Rack::Utils.escape_html(@data_object.title)}</h2>"
			end
		end
	end
end
