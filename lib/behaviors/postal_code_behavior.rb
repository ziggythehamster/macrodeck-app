module MacroDeck
	# Postal codes shouldn't be shown (they're part of addresses)
	# Except they're perfectly valid to edit.
	class PostalCodeBehavior < Behavior
		def to_form_field
			output = ""
			output << form_label(:postal_code)
			output << form_input(:postal_code, :text, { :size => 10 })
			return output
		end
	end
end
