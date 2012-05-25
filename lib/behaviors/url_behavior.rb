module MacroDeck
	# Renders a URL.
	class UrlBehavior < Behavior
		def to_html
			if @data_object.url =~ /^http:\/\// || @data_object.url =~ /^https:\/\//
				return "<p><a href=\"#{Rack::Utils.escape_html(@data_object.url)}\" target=\"_blank\" class=\"url\">#{Rack::Utils.escape_html(@data_object.url)}</a></p>"
			else
				return "<p><a href=\"http://#{Rack::Utils.escape_html(@data_object.url)}\" target=\"_blank\" class=\"url\">#{Rack::Utils.escape_html(@data_object.url)}</a></p>"
			end
		end

		def to_form_field(field_name = :url, params = {})
			if params[:name].nil?
				name = field_name
			else
				name = params[:name]
			end

			output = ""
			output << form_label(field_name, :name => name)
			output << form_input(field_name, :text, { :name => name })
			return output
		end
	end
end
