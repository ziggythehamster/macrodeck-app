module MacroDeck
	# Renders a URL.
	class UrlBehavior < Behavior
		def to_html
			if @data_object.url =~ /^http:\/\// || @data_object.url =~ /^https:\/\//
				return "<p><a href=\"#{@data_object.url}\" target=\"_blank\">#{@data_object.url}</a></p>"
			else
				return "<p><a href=\"http://#{@data_object.url}\" target=\"_blank\">#{@data_object.url}</a></p>"
			end
		end
	end
end
