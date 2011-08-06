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
			output << date_picker_field("date", Time.new.strftime("%F")) if @data_object.date.nil?
			output << date_picker_field("date", Date.parse(@data_object.date).strftime("%F")) unless @data_object.date.nil?
			return output
		end

		def parse_result(result)
			if !result["noend"].nil?
				return nil
			else
				return parse_date_result(result)
			end
		end

		private
			def parse_date_result(result)
				return Date.parse(result["date"]).strftime("%F")
			end

			def no_end_picker_field(name, hide, caption)
				output  = "<input type=\"checkbox\" id=\"#{Rack::Utils.escape_html(name)}_noend\" name=\"#{Rack::Utils.escape_html(name)}[noend]\" value=\"1\""
				output << "checked=\"checked\" " if hide
				output << "/> #{Rack::Utils.escape_html(caption)}"
				return output
			end

			def date_picker_field(name, value)
				"<input type=\"hidden\" id=\"#{Rack::Utils.escape_html(name)}_date\" name=\"#{Rack::Utils.escape_html(name)}[date]\" value=\"#{Rack::Utils.escape_html(value)}\" />
				<div id=\"#{Rack::Utils.escape_html(name)}_datepicker\"></div>
				<script type=\"text/javascript\">
				//<![CDATA[
					jQuery(document).ready(function() {
						jQuery(\"##{Rack::Utils.escape_html(name)}_datepicker\").datepicker({ altField: \"##{Rack::Utils.escape_html(name)}_date\", altFormat: \"yy-mm-dd\", dateFormat: \"yy-mm-dd\" });
						jQuery(\"##{Rack::Utils.escape_html(name)}_datepicker\").datepicker(\"setDate\", \"#{Rack::Utils.escape_html(value)}\");
					});
				//]]>
				</script>"
			end
	end
end
