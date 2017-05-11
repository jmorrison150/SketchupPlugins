require 'liveParametric.rb'

class CubeStack < LiveParametric
	@@numBlocksStr = "Number of Blocks"
	@@blockEccentricityStr = "Block Eccentricity"
	@@rotationStr = "Rotation Degrees"
	def default_variables
		[
			Slider.new(@@numBlocksStr, 2, 10, 5, true),
			Slider.new(@@blockEccentricityStr, 0.1, 10, 1),
			Slider.new(@@rotationStr, 0,90, 0)
			]
	end
	
	def create_entities( data, container)	
		numBlocks = data[@@numBlocksStr]
		eccentricity = data[@@blockEccentricityStr]
		rotationAngle = data[@@rotationStr].degrees
		
		d = 100.cm
		h = 100.cm
		w = d*eccentricity
		
		g = container.add_group
		
		f = g.entities.add_face([0,0,0], [w,0,0], [w,d,0], [0,d,0])
		f.pushpull(-h)
		
		1.upto(numBlocks-1){|i|
			newG = g.copy
			lift = Geom::Transformation.new([0,0,h*i])
			rotate = Geom::Transformation.rotation([0,0,0],[0,0,1], rotationAngle*i)
			newG.transform!(lift*rotate)
		}
	end
		
end
	
