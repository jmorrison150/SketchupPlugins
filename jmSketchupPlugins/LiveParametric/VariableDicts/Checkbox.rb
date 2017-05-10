require 'VariableDict.rb'

class Checkbox < VariableDict
    def initialize( varTitle, defaultValue=false)
        super( varTitle)
        @curVal = defaultValue
        @html_height = 40
    end

    def to_b(str)
        case str.downcase.strip
        when 'true', 'yes', 'on', 't', '1', 'y', '=='
            return true
        when 'nil', 'null'
            return nil
        else
            return false
        end
    end

    def setVal( val)
        if val.kind_of?(String)
            @curVal = to_b(val)
        else
            @curVal = val
        end
    end

    def to_html
        table_width = html_width - 25
        table_height = html_height - 10
        checkedVal = @curVal ? "checked='yes'" : ''

        htmlStr = <<-EOS
        <table border="0" width=#{table_width}px height=#{table_height} align="left">
        <tr><td align ="left">
			<label>
        	<input type="checkbox" id="#{unique_id}" #{checkedVal} onchange = "did_change('#{unique_id}', this.checked);">
			#{@varTitle}
        	</label>
		</td></tr>
        </table>
        <br>
        EOS

        htmlStr
    end

end
