require 'liveParametric.rb'

class LPDemo < LiveParametric
	@@bigSquareStr = "Big Square? "
	@@sizeStr = "Size"
	@@shapeStr = "Shape"
	@@shapeLabelStr = "Label"
	def default_variables
		[
			Checkbox.new( 	@@bigSquareStr, true),
			Slider.new( @@sizeStr, 10, 100, 100),
			# RadioButton and DropdownList do the same thing here
			DropdownList.new( @@shapeStr, ["Square", "Triangle", "Circle"], "Circle"),
			# RadioButton.new( @@shapeStr, ["Square", "Triangle", "Circle"], "Circle"),
			TextField.new( @@shapeLabelStr, "Type Label Here")
		]
	end

    def create_entities( data, container)

		bigSquare 	= data[@@bigSquareStr]
		size 		= data[@@sizeStr]
		which_shape = data[@@shapeStr]
		text 		= data[@@shapeLabelStr]

		triArr = [[0,0,0], [size,0,0], [size,size,0]]
		squareArr = triArr + [[0,size,0]]

		if bigSquare; container.add_face( squareArr.map{|p| p.map{|v| 2*v}}) end

		shape = case which_shape
		when /Square/; 		container.add_face( squareArr)
		when /Triangle/; 	container.add_face( triArr)
		when /Circle/; 		container.add_circle( [0,0,0], [0,0,1], size)
		else puts "Error: #{which_shape} doesn't match!"
		end

		container.add_text( text, [size+10,size,0])

	end
end
