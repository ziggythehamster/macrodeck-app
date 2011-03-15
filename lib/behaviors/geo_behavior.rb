module MacroDeck
	# Renders a geolocation as a Google Maps static map
	class GeoBehavior < Behavior
		def to_html
			"<p><img src=\"http://maps.google.com/maps/api/staticmap?size=300x300&amp;zoom=15&amp;markers=size:mid%7C#{Rack::Utils.escape_html(@data_object.lat)},#{Rack::Utils.escape_html(@data_object.lng)}&amp;maptype=roadmap&amp;sensor=false\" alt=\"Map of #{Rack::Utils.escape_html(@data_object.title)}\" /></p>"
		end
	end
end
