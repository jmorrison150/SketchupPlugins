# Copyright 2004-2005, @Last Software, Inc.

# This software is provided as an example of using the Ruby interface
# to SketchUp.

# Permission to use, copy, modify, and distribute this software for
# any purpose and without fee is hereby granted, provided that the above
# copyright notice appear in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------

# Example Ruby script for creating onion domes.

require 'parametric.rb'
require 'bezier.rb'
require 'mesh_additions.rb'

#=============================================================================

class OnionDome < Parametric

def create_entities(data, container)

    r = data["r"]
    h = data["h"]
    r1 = data["r1"]
    h1 = data["h1"]
    r2 = data["r2"]
    h2 = data["h2"]
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
#if( not file_loaded?("oniondome.rb") )
#    UI.menu("Draw").add_item("Onion Dome") { OnionDome.new }
#
#    file_loaded("oniondome.rb")
#end
