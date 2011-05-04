module MacroDeck
	# Renders tips associated with an object. Only has HTML associated.
	class TipsBehavior < Behavior
		def to_html
			html =  "<h2>Tips</h2>"
			if @data_object.tips && @data_object.tips.length > 0
				@data_object.tips.each do |tip|
					html << "<q>#{Rack::Utils.escape_html(tip[0])}"
					if !tip[1].nil? && !tip[1]["name"].nil?
						html << " <cite>"
						if !tip[1]["foursquare_user_id"].nil?
							html << "<a href=\"http://www.foursquare.com/user/#{Rack::Utils.escape_html(tip[1]["foursquare_user_id"])}\" target=\"_blank\">#{Rack::Utils.escape_html(tip[1]["name"])}</a>"
						else
							html << "#{Rack::Utils.escape_html(tip[1]["name"])}"
						end

						html << "</cite>"
					end
					html << "</q>"
				end
			end
			return html
		end
	end
end
