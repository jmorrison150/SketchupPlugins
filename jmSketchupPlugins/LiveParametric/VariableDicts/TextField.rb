require 'VariableDict.rb'

class TextField < VariableDict
    def initialize( varTitle, defaultValue='')
        super( varTitle)
        @curVal = defaultValue
        @html_height = 40
    end

    def to_html
        table_width = html_width - 25
        table_height = html_height - 10
       
		
		htmlStr = %Q~#{@varTitle}:&nbsp&nbsp<input type="text" id="#{unique_id}" value= "#{@curVal}" onkeyup="did_change('#{unique_id}', this.value);">~
		

        # htmlStr = <<-EOS
        #         <table border="0" width=#{table_width}px height=#{table_height} align="left">
        #         <tr><td align ="left">
        # 			#{@varTitle}:<input type="text" id="#{unique_id}" defaultValue= "#{@curVal}" onchange = "did_change('#{unique_id}', this.value);">
        # 			</td></tr>
        #         </table>
        #         <br>
        #         EOS

        htmlStr
    end

end
