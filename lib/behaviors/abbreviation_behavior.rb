module MacroDeck
	# An abbreviation should be outputted as (US) for example.
	class AbbreviationBehavior < Behavior
		def to_html
			"(#{@value})"
		end
	end
end
