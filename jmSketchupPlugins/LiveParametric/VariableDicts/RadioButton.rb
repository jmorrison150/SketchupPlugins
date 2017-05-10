require 'VariableDict.rb'

class RadioButton < VariableDict
    def initialize( varTitle, possibleValues, defaultValue=nil)
        super( varTitle)
        @curVal = defaultValue
		@possibleValues = possibleValues
    end

	def to_html
		table_width = html_width - 25
		row_height = 30
		@html_height = row_height*(@possibleValues.length+1)
		table_height = html_height - 10
		
		htmlStr = <<-EOS
				<table border="0" id="#{unique_id}" width=#{table_width}px  align="left">
				<tr><td colspan=2 align='center'>#{title}</td></tr>\n
				EOS
	
		htmlStr += @possibleValues.map{|p| 
			checkedStr = (p == @curVal ? "checked='yes'": '')
			button_id = "#{unique_id}_#{p}"
 
			 %Q~<tr height='#{row_height}'><td><label>
			 			<input type="radio" name="#{unique_id}" id="#{button_id}" onClick="did_change( '#{unique_id}', '#{p}' );" #{checkedStr}>
						#{p}
			 	</label></td></tr>~
		}.join("\n")
		htmlStr += "</table>"

		htmlStr
	end

end
