require 'ParameterDict.rb'
class LiveParametricHTMLWriter
	attr_reader :width, :height, :html, :filename
	
    # --Accept an array of controller objects
    # --write an html file into a custom control panel
    # --register for all the necessary callbacks
    # --relay whatever calls necessary to calling class

	def initialize( controlDictArr, file = nil)
		@filename = file
		@dict = controlDictArr
		@html = htmlStr( @dict)
		findPageDimensions( @dict)
	 	File.open(filename, "w"){ |f| f.write(@html)} if filename
	end
	
	def delete_file
		File.delete(@filename) if filename
	end

	def findPageDimensions( dict)
		# Let's assume a column of tables.  So add heights and take the largest width
		w = dict.variableDicts.map{|d| d.html_width}.max
		h = dict.variableDicts.map{|d| d.html_height}.inject(0){|sum, val| sum+val	}
		h += 40 # SketchUp's WebDialog header
				
		@width = w
		@height = h
	end
	
    def htmlStr(controlDictArr)
        buildStr = <<-EOS
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" 
 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
#{headerCode(controlDictArr)}
#{bodyCode(controlDictArr)}
</html>
        EOS
       buildStr
    end

    def headerCode( controlDictArr)
        #figure out which files we need to include:
  
		header = controlDictArr.variableDicts.map{|d| d.headerCode}.flatten.uniq
		headerStr = <<-EOS
<head>
<meta http-equiv="Content-type" content="text/html; charset=utf-8" />

#{header.join("\n")}

</head>
EOS
	headerStr
    end

    def bodyCode( controlDictArr)
		# Each element of controlDictArr returns html to control itself.  
		# Place each block of html in a table running vertically down in one column.
		# Feel free to change this layout around if there's something you'd like different.
		controlStr = "<table border=0 align='center'>\n<tr><td>\n"
		controlStr += controlDictArr.variableDicts.map{|dict| dict.to_html}.join("</td></tr>\n<tr><td>\n")
		controlStr += "</td></tr>\n<table>\n"
	
        bodyStr = %Q~
<body>
#{controlStr}

#{callbackCode}
</body>
~
        bodyStr
    end

	def callbackCode( )
		# JS function to gather strings & labels from each variableDict into 
		# a list and return them to the SU ruby code
		callbackStr = <<-EOS
		<script language="javascript">
		function did_change(elementID, elementValue)
		{
			window.location='skp:did_change@'+elementID+','+elementValue;
		}
		
		</script>
		EOS
		callbackStr
	end
end


