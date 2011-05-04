module MacroDeck
	# Renders tips associated with an object. Only has HTML associated.
	class TipsBehavior < Behavior
		def to_html
			html =  "<h2>Tips</h2>"
			if @data_object.tips && @data_object.tips.length > 0
				@data_object.tips.each do |tip|
					html << "<q>#{Rack::Utils.escape_html(tip[0])}"
					html << " <cite>#{Rack::Utils.escape_html(tip[1]["name"])}</cite>" if !tip[1].nil? && !tip[1]["name"].nil?
					html << "</q>"
				end
			end
			return html
		end
	end
end
