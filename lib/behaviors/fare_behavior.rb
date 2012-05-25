module MacroDeck
	# Renders a list of fares as a list of items, concatenated by commas.
	class FareBehavior < Behavior
		def to_form_field(field_name = :fare, params = {})
			if params[:name].nil?
				name = field_name
			else
				name = params[:name]
			end

			out  = form_label(field_name, :name => name)
			out << form_input(field_name, :text, { :name => name })
			return out
		end

		def to_html
			Rack::Utils.escape_html(@data_object.fare.join(", "))
		end
	end
end
