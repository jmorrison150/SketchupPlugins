
# Example Ruby script for creating onion domes.

require 'parametric.rb'
require 'bezier.rb'
require 'mesh_additions.rb'

#=============================================================================

class OnionDomeLP < LiveParametric

def default_variables
	[ 	Slider.new("Radius", 0.5.feet, 4.feet, 2.feet),
		Slider.new("Height", 2.feet, 12.feet, 4.feet),
		Slider.new("Radius 2", 1.feet, 8.feet, 3.feet),
		Slider.new("Height 2", 1.feet, 4.feet, 2.feet),
		Slider.new("Radius 3", 2.inch, 18.inch, 6.inch),
		Slider.new("Height 3", 2.feet, 6.feet, 3.feet)
		]
end

def create_entities(data, container)

    r  = data["Radius"]
    h  = data["Height"]
    r1 = data["Radius 2"]
    h1 = data["Height 2"]
    r2 = data["Radius 3"]
    h2 = data["Height 3"]
    n1 = 24
    n2 = 16

    # Create the Bezier curve to sweep
    pts = []
    pts[0] = [r, 0, 0]
    pts[1] = [r1, 0, h1]
    pts[2] = [r2, 0, h2]
    pts[3] = [0, 0, h]
    curvepts = Bezier.points(pts, n2)

    # create the mesh and revolve the points
    axis = [ORIGIN, Z_AXIS]
    numpts = n1 * n2
    numpoly = n1 * (n2-1)
    mesh = Geom::PolygonMesh.new numpts, numpoly
    mesh.add_revolved_points curvepts, axis, n1

    # Create the faces from the mesh
    container.add_faces_from_mesh mesh, 12

end

def default_parameters
    defaults = ["r", 2.feet, "h", 4.feet, "r1", 3.feet, "h1", 2.feet, "r2", 6.inch, "h2", 3.feet]
    defaults
end

def translate_key(key)
    prompt = key
    case( key )
        when "r"
            prompt = "Radius"
        when "h"
            prompt = "Height"
    end
    prompt
end


end # class OnionDome

#=============================================================================
# Add a menu to create shapes
#if( not file_loaded?("oniondome_lp.rb") )
#    UI.menu("Draw").add_item("Onion Dome LP") { OnionDomeLP.new }
#
#    file_loaded("oniondome_lp.rb")
#end
