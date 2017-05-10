require 'VariableDict.rb'

class Slider < VariableDict
    attr_reader :minVal, :maxVal, :curVal, :integerOnly, :showMinMax

    def initialize( varTitle, minVal=0, maxVal=1.0, curVal=0.5, integerOnly=false, showMinMax=false)
        super(varTitle)
        @minVal = minVal
        @maxVal = maxVal
        @curVal = curVal
        @integerOnly = integerOnly
        @showMinMax = showMinMax
        
        @html_width = 200
        @html_height = 55
        
        @html_height += 20 if showMinMax

    end
    def val
        @curVal
    end

	def setVal( val)
		if integerOnly
			@curVal = val.to_i
		else
			@curVal = val.to_f
		end
	end
	
	def headerCode
		[	%Q~<script src="../javascripts/scriptaculous/prototype.js" type="text/javascript"></script>~,
			%Q~<script src="../javascripts/scriptaculous/slider.js"    type="text/javascript"></script>~,
        	cssStr
		]
	end

	def cssStr 
		<<-EOS
		<style type="text/css">
		/* put the left rounded edge on the track */
		div.track-left {
			position: absolute;
			width: 5px;
			height: 20px;
			background: transparent url(../images/slider-images-track-left.png) no-repeat top left;
		}
		/* put the track and the right rounded edge on the track */
		div.track {
			background: transparent url(../images/slider-images-track-right.png) no-repeat top right;
		}
		div.handle {
			width: 19px;
			height: 20px;
			background: url(../images/slider-images-handle.png);
			float: left;
			cursor:move;
		}
		</style>
		EOS
	end

    def to_html
        sliderWidth = @html_width -25

        # This code puts the javascript for a slider directly after the code for its
        # appearance. Scriptaculous's comments warn that this may create problems
        # when used with IE.  Be warned, should problems arise - ETJ 24-Jul-2007
        title = varTitle
        cur = sprintf("%.2f",curVal)
        min = sprintf("%.2f",minVal)
        max = sprintf("%.2f",maxVal)

       
        slider_id = unique_id+"_slider"
        left_id   = unique_id+"_left"
        handle_id = unique_id+"_handle"
        rValStr = 'v.toFixed(2)'
        if integerOnly
            cur = curVal.to_i
            min = minVal.to_i
            max = maxVal.to_i
			rValStr = 'v.toFixed(0)' 
		end
		
		onChangeStr = %Q~function(v) { 
			$('#{unique_id}').innerHTML = #{rValStr};
			did_change('#{unique_id}', $('#{unique_id}').innerHTML);
		}\n~
        
        minMaxStr = ""
        if showMinMax
            minMaxStr = %Q{\n        <tr><td align ="left">#{min}</td><td align="right">#{max}</td></tr>\n}
        end
        
        sliderStr = <<-EOS
        <table border="0" width=#{sliderWidth}px align="center">
        <tr><td align ="left">#{title}:</td><td align="right"id="#{unique_id}">#{cur}</td></tr>
        <tr><td colspan="2">
        	<div 	 id="#{slider_id}" 	class="track"  style="width:#{sliderWidth}px; height:20px">
       			<div id="#{left_id}" 	class="track-left"></div>
       			<div id="#{handle_id}" 	class="handle" style="float:left"></div>
       		</div>
        </td></tr>#{minMaxStr}
        </table>

        <script type="text/javascript" language="javascript">
        // horizontal slider control
        new Control.Slider('#{handle_id}', '#{slider_id}', {
            range: $R(#{min},#{max}),
            sliderValue: #{cur} ,
            onSlide:  #{onChangeStr},
            onChange: #{onChangeStr}
        }
        );
        </script>
        EOS

        sliderStr
    end
end
