module MacroDeck
	# An abbreviation should not be outputted (this is the default Behavior)
	# It exists in the title. But it should be editable.
	class AbbreviationBehavior < Behavior
		def to_form_field
			output = ""
			output << form_label(:abbreviation)
			output << form_input(:abbreviation, :text, { :size => 3 })
			return output
		end
	end
end
