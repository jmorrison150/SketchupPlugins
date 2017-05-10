require 'VariableDict.rb'

class DropdownList < VariableDict
    def initialize( varTitle, possibleValues, defaultValue=nil)
        super( varTitle)
        @curVal = defaultValue
		@possibleValues = possibleValues
    end

	def to_html
		table_width = html_width - 25
		row_height = 34
		@html_height = row_height*(@possibleValues.length+1)
		table_height = html_height - 10

		htmlStr = %Q~
		#{title}:&nbsp&nbsp<select id='#{unique_id}' onChange="did_change( '#{unique_id}', this[this.selectedIndex].text);">\n~
		htmlStr += @possibleValues.map{|p| 
			selectedStr = (p == @curVal ? "selected='yes'": '')
			%Q~<option #{selectedStr}>#{p}</option>\n~
		}.join
		htmlStr += "</select>"

		htmlStr
	end
end
