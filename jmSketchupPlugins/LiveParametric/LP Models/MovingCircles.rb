require 'liveParametric'

class MovingCircles < LiveParametric
@@numCirclesStr = "Number of Circles"
@@radStr = "Radius"

def create_entities( data, container)
	perturbationRad = data[@@radStr]
	numCircles = data[@@numCirclesStr]
	rad = 10.cm
	
	origin = Geom::Point3d.new( 0,0,0)
	zVec = Geom::Vector3d.new(0,0,1)
	container.add_circle( origin, zVec, rad)
	
	numCircles.times { |n| 
		angle = n * 360.degrees/numCircles
		rot = Geom::Transformation.rotation( origin, zVec, angle)
		newPt = Geom::Point3d.new(perturbationRad*rad*2,0,0).transform(rot)
		
		container.add_circle( newPt, zVec, rad)
	}	
end

def default_variables
	[
		Slider.new( @@numCirclesStr, 2, 12, 6, true),
		Slider.new( @@radStr)
	]
end
	
end