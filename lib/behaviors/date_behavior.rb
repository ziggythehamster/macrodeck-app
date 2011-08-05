require "date"

module MacroDeck
	# Date is a basic building block control.
	class DateBehavior < Behavior
		def to_html
			return Rack::Utils.escape_html(@data_object.date)
		end

		def to_form_field
			output = ""
			output << "<label for=\"date_date\">Date</label>"
			output << date_picker_field("date", @data_object.date)
			return output
		end

		def parse_result(result)
			return parse_date_result(result)
		end

		private
			def parse_date_result(result)
				return Date.parse(result["date"]).strftime("%F")
			end

			def date_picker_field(name, value)
				"<input type=\"hidden\" id=\"#{Rack::Utils.escape_html(name)}_date\" name=\"#{Rack::Utils.escape_html(name)}[date]\" value=\"#{Rack::Utils.escape_html(value)}\" />
				<div id=\"#{Rack::Utils.escape_html(name)}_datepicker\"></div>
				<script type=\"text/javascript\">
				//<![CNAME[
					jQuery(document).ready(function() {
						jQuery(\"##{Rack::Utils.escape_html(name)}_datepicker\").datepicker({ altField: \"##{Rack::Utils.escape_html(name)}_date\", altFormat: \"yy-mm-dd\" });
					});
				//]]>
				</script>"
			end
	end
end
