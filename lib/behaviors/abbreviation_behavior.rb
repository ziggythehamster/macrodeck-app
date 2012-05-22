module MacroDeck
	# An abbreviation should not be outputted (this is the default Behavior)
	# It exists in the title. But it should be editable.
	class AbbreviationBehavior < Behavior
		def to_form_field(field_name = :abbreviation, params = {})
			if params[:name].nil?
				name = field_name
			else
				name = params[:name]
			end

			output = ""
			output << form_label(name)
			output << form_input(name, :text, { :size => 3 })
			return output
		end
	end
end
