# Copyright 2004, @Last Software, Inc.

# This software is provided as an example of using the Ruby interface
# to SketchUp.

# Permission to use, copy, modify, and distribute this software for 
# any purpose and without fee is hereby granted, provided that the above
# copyright notice appear in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------

# Functions for getting and setting the camera position

require 'sketchup.rb'

#=============================================================================

# TODO:  These are generally useful methods that I should probably put someplace.
# It gets all of the values in an AttributeDictionary as a Hash.  This is really
# most useful for a ComponentInstance.  It will get the attibutes from the
# ComponentDefinition and then over-ride any instance specifiic values.

class Sketchup::Entity
def get_attributes(dictname)
    attribs = {}
    dict = self.attribute_dictionary(dictname)
    if( dict )
        dict.each {|k, v| attribs[k] = v}
    end
    attribs
end

# Determine if an Entity has attributes with the given name
def has_attributes?(dictname)
    self.attribute_dictionary(dictname) != nil
end

end # class Sketchup::Entity

class Sketchup::ComponentInstance
def get_attributes(dictname)
    # First get the attributes from the definition
    attribs = {}
    dict = self.definition.attribute_dictionary(dictname)
    if( dict )
        dict.each {|k, v| attribs[k] = v}
    end
    # now override these with any values that are set on the instance
    dict = self.attribute_dictionary(dictname)
    if( dict )
        dict.each {|k, v| attribs[k] = v}
    end
    attribs
end

# For a ComponentInstance the attributes can be on either the instance
# or the definition
def has_attributes?(dictname)
    self.attribute_dictionary(dictname) != nil || self.definition.attribute_dictionary(dictname) != nil
end

end # class Sketchup::ComponentInstance

#=============================================================================
class CameraRep

@@last_selected_name = nil

# this is used to control the transition to a saved camera
@@default_transition_time = 1.0

def initialize(data = nil)
    @rep = nil
    
    if( data.kind_of? Sketchup::Entity )
        @rep = data
    elsif( data.kind_of? Sketchup::View )
        if not self.load_camera(data)
            self.create_geometry(data)
        end
        self.prompt_for_name
    else
        @rep = nil
    end
    @offset = nil
end

def geometry
    @rep
end

def model
    return nil if not @rep
    @rep.model
end

def view
    model = self.model
    return nil if not model
    model.active_view
end

# Get the eye offset from the camera representation
def get_offset
    if @offset == nil and @rep
        attribs = @rep.get_attributes "camera"
        if( attribs )
            eo = attribs["eo"]
            if( eo.kind_of?(Array) and eo.length == 3 )
                @offset = eo
            end
        end
        @offset = false if @offset == nil
    end
    @offset
end

# Create a transformation from a view
def CameraRep.get_transform_from_view(view, obj = nil)
    camera = view.camera
    origin = camera.eye
    xaxis = camera.target - origin
    xaxis.normalize!
    zaxis = camera.up
    yaxis = zaxis * xaxis
    
    # see if there is an eye offset that should be applied
    if( obj )
        eo = obj.get_attribute "camera", "eo"
        if( eo and eo.kind_of?(Array) and eo.length == 3 )
            offset = Geom::Vector3d.linear_combination eo.x, xaxis, eo.y, yaxis, eo.z, zaxis
            origin.offset!(offset.reverse)
        end
    end
    
    return Geom::Transformation.new( origin, xaxis, yaxis )
end

# Get the material to use for the faces that show the viewing volume
def get_frustum_material
    materials = Sketchup.active_model.materials
    material = materials["Camera_FOV"]
    if( not material )
        material = materials.add "Camera_FOV"
        material.color = [211, 211, 211]
        material.alpha = 0.25
    end
    material
end

# Get a point at a corner of a view frustum
def view_corner(view, index, distance, transform)
    ray = view.pickray(view.corner(index))
    if ray
        pt = ray[0].offset ray[1], distance
    else
        pt = view.camera.eye
    end
    pt.transform transform
end

# Compute the distance from the camera to the back of the model.
# This is used for showing the viewing frustum
def distance_to_back(view)
    bb = view.model.bounds
    eye = view.camera.eye
    dir = view.camera.direction
    distance = 0.0.inch
    for i in 0..7 do
        vec = Geom::Vector3d.new(eye, bb.corner(i))
        d = vec % dir
        if( d > distance )
            distance = d
        end
    end
    if( distance == 0.0 )
        distance = eye.distance(view.camera.target)
    end
    distance
end

# Show the view volume using faces
def show_volume_faces(view, entities)
    model = view.model
    material = self.get_frustum_material
    bounds = model.bounds
    bounds.add view.camera.eye
    length = bounds.diagonal
    transform = CameraRep.get_transform_from_view(view).inverse
    pts = (0..3).collect {|i| self.view_corner view, i, length, transform}
    face = entities.add_face ORIGIN, pts[0], pts[2]
    face.material = material
    face = entities.add_face ORIGIN, pts[2], pts[3]
    face.material = material
    face = entities.add_face ORIGIN, pts[3], pts[1]
    face.material = material
    face = entities.add_face ORIGIN, pts[1], pts[0]
    face.material = material
end

# Show the view volume using construction lines
def show_volume_lines(view, entities)
    # get rays to the 4 corners of the viewing area
    transform = CameraRep.get_transform_from_view(view).inverse
    #length = self.distance_to_back(view)
    #pts = []
    for i in 0..3
        ray = view.pickray(view.corner(i))
        dir = ray[1].transform(transform)
        line = entities.add_cline ORIGIN, dir, "..."
        line.start = ORIGIN
        #pts[i] = ORIGIN.offset dir, length
        #entities.add_cline ORIGIN, pts[i], "..."
        #if( i > 0 )
        #    entities.add_cline pts[i-1], pts[i], "..."
        #end
    end
    #entities.add_cline pts[3], pts[0], "..."
end

# Create a camera rep from a camera component file
def load_camera(view)
    # Find the path for a camera component
    path = nil
    
    # First look for a component with the same name as the
    # description of the default camera
    name = view.camera.description
    if( name and not name.empty? )
        name << ".skp"
        path = Sketchup.find_support_file name, "plugins/previs"
    end
    
    # if we didn't find a component there, try using the defulat name
    if( not path or path.empty? )
        path = Sketchup.find_support_file "default_camera.skp", "plugins/previs"
    end

    return nil if not path or path.empty?

    # Now load this component
    model = view.model
    return if not model
    definition = model.definitions.load path
    return nil if not definition
    
    # Create a component instance
    transform = CameraRep.get_transform_from_view(view, definition)
    @rep = model.entities.add_instance definition, transform
    self.set_attributes(view.camera)

    @rep
end

# Create the geometry that represents a camera
def create_geometry(view)
    model = view.model
    camera = view.camera
    
    model.start_operation "Create Camera"
    group = model.entities.add_group
    entities = group.entities
    
    # Put the camera on a new layer so that we can turn off the display of all cameras
    # note that the "add" method for layers will not add one if there is already
    # one with the given name
    layer = model.layers.add("Cameras")
    group.layer = layer
    
    # Hardcoded parameters for the size of the camera
    w2 = 2  # actually, half the width
    h2 = 6  # half the height
    l = 24  # the length
    r1 = 2
    r2 = 3.5
    
    # Create the body of the camera
    p1 = [-l, -w2, -h2]
    p2 = [-6, -w2, -h2]
    p3 = [-6, w2, -h2]
    p4 = [-l, w2, -h2]
    face = entities.add_face p1, p2, p3, p4
    face.pushpull(2*h2)
    
    # Create the lens
    # REVIEW:  I am creating the camera geometry so that the front of the lense is
    # at the eye position.  This is probably not really correct.  I should probably
    # have the film plane at the eye position.  I am doing it this way for now so
    # that the camera geometry will never be visible.  I could control this using
    # the near clipping plane, but we don't currently have any way to set that.
    numpts = 8
    angle = Math::PI*2.0/numpts
    pts1 = (0..8).collect {|i|
        a=i*angle; Geom::Point3d.new(-6, r1*Math.sin(a), r1*Math.cos(a))
    }
    pts2 = (0..8).collect {|i|
        a=i*angle; Geom::Point3d.new(0, r2*Math.sin(a), r2*Math.cos(a))
    }
    (1..8).each {|i|
        im1 = i-1
        entities.add_face(pts1[i], pts1[im1], pts2[im1], pts2[i])
    }

    # Create some transparent faces that show the viewing area
    if( camera.perspective? )
        layer = model.layers["Camera_FOV"]
        if( not layer )
            layer = model.layers.add("Camera_FOV")
            layer.visible = false
        end
        oldlayer = model.active_layer
        model.active_layer = layer
        
        #self.show_volume_faces(view, entities)
        self.show_volume_lines(view, entities)
        
        model.active_layer = oldlayer
    end
    
    # Now transform it to where the camera is
    transform = CameraRep.get_transform_from_view(view)
    group.move!(transform)
    
    # Save the camera parameters (other than orientation) as attributes
    @rep = group
    self.set_attributes(camera)
    
    model.commit_operation
    @rep
end

# Get the camera attributes from the representation
def attributes
    return nil if not @rep
    @rep.get_attributes "camera"
end

# Set the attributes on the representation
def set_attributes(camera, name = nil)
    return nil if not @rep
    
    # Make this look like a single operation
    model = @rep.model
    model.start_operation "Camera Properties" if model
    
    # First get the camera attributes on the entity.
    attribs = @rep.attribute_dictionary("camera", true)
    
    # Now assign the values
    attribs["name"] = name if name

    perspective = camera.perspective?
    attribs["p"] = perspective
    if( perspective )
        attribs["fov"] = camera.fov
    else
        attribs["h"] = camera.height
    end
    attribs["ar"] = camera.aspect_ratio
    attribs["iw"] = camera.image_width
    
    model.commit_operation if model
end

# Update this CameraRep so that it matches the given camera
def update(camera)
    return if @rep == nil
    
    # Compute the new transformation from the camera
    eye = camera.eye
    xaxis = camera.direction
    yaxis = camera.xaxis.reverse
    zaxis = camera.yaxis
    
    # See if an eye offset is given
    eo = self.get_offset
    if( eo )
        offset = Geom::Vector3d.linear_combination eo.x, xaxis, eo.y, yaxis, eo.z, zaxis
        eye.offset!(offset.reverse)
    end
    
    t = Geom::Transformation.new( eye, xaxis, yaxis )
    @rep.move!(t)
    
    # Set the camera attributes
    self.set_attributes(camera)
end

# Get the orientation of the camera
# returned as an Array [eye, dir, up]
def orientation
    return nil if not @rep

    # get the transformation from the group or component instance
    t = @rep.transformation
    eye = t.origin
    dir = t.xaxis
    up = t.zaxis
    y = t.yaxis

    # See if there is an offset that needs to be applied to the eye position
    eo = self.get_offset
    if( eo )
        offset = Geom::Vector3d.linear_combination eo.x, dir, eo.y, y, eo.z, up
        eye.offset!(offset)
    end

    [eye, dir, up]
end

# Get the Camera that is represented by the object
def get_camera
    return nil if not @rep
    camera = nil
    
    # Get the camera position and orientation
    a = self.orientation
    
    # Get the original parameters from the attached attributes
    attribs = self.attributes

    if attribs
        perspective = attribs["p"]
        perspective = true if perspective == nil
        if( perspective )
            value = attribs["fov"]
            value = 45.0 if not value
        else
            value = attribs["h"]
        end
        
        camera = Sketchup::Camera.new(a[0], a[1], a[2], perspective, value)

        ar = attribs["ar"]
        camera.aspect_ratio = ar if ar
        iw = attribs["iw"]
        camera.image_width = iw if iw
        
    else
        # If there are no camera attributes, then just set the orientation
        camera = Sketchup::Camera.new(a[0], a[1], a[2])
    end
    
    camera
end

# Activate this camera
def activate()
    return if not @rep
    model = @rep.model
    return if not model
    view = model.active_view
    return if not view
    transition_time = @@default_transition_time

    
    # Set the camera
    camera = self.get_camera
    if( camera )
        view.camera = camera, transition_time
    end
    
    # Remember this as the last activated camera
    @@last_selected_name = self.name
    
    model.selection.clear
    model.select_tool(CameraTool.new(@rep))
end

# prompt for a name and assign it to a camera
def prompt_for_name
    return if not @rep
    model = @rep.model
    return if not model
    cameras = CameraRep.cameras_in_model model
    name = "Camera"
    name << " #{cameras.length}" if cameras.length > 0
    prompts = ["Name"]
    values = [name]
    results = inputbox prompts, values, "Camera Name"
    
    if( results )
        self.name = results[0]
        @@last_selected_name = results[0]
    end

end

# get the name of the camera
def name
    return "" if not @rep
    @rep.get_attribute "camera", "name", ""
end

# name a camera
def name=(name)
    return if not @rep
    @rep.set_attribute "camera", "name", name
end

# Get the camera height
def height
    a = self.orientation
    return 0.inch if not a
    a[0].z
end

# Set the camera height
# I'm doing this as a set rather than height= so that I can pass in an
# optional argument to control whether or not to also update the view
def set_height(h, view=nil)
    return if not @rep
    
    # get the current height
    current_height = self.height
    return if current_height == h
    
    # Move it to the new height
    dz = h - current_height
    t = @rep.transformation
    t2 = Geom::Transformation.translation [0, 0, dz]
    t = t2 * t
    @rep.move!(t)

    # Now update the view if needed
    if( view )
        camera = self.get_camera
        if( camera )
            view.camera = camera, 0.5
        end
    else
        view = @rep.model.active_view
        view.invalidate if view
    end
end

# Get the tilt.  This is the angle between the camera and horizontal
def tilt
    a = self.orientation
    return 0 if not a
    
    # The direction is the second value in the array
    dir = a[1]
    
    # Compute the angle betwen the direction and [0,0,1] and subtract 90 degrees
    angle = dir.angle_between(Z_AXIS) - Math::PI/2.0
    -angle
end

def set_tilt(angle, view=nil)
    # We need to rotate the camera about the eye position so that the tilt angle
    # matches the given angle

    # get the current tilt angle
    current_tilt = self.tilt
    return if current_tilt == angle

    # We will rotate about an axis though the eye
    a = self.orientation
    eye = a[0]
    axis = a[1] * a[2]
    da = angle - current_tilt
    
    t = @rep.transformation
    t2 = Geom::Transformation.rotation eye, axis, da
    t = t2 * t
    @rep.move!(t)

    # Now update the view if needed
    if( view )
        camera = self.get_camera
        if( camera )
            view.camera = camera, 0.5
        end
    else
        view = @rep.model.active_view
        view.invalidate if view
    end
end

# deit the properties of a camera
def edit(update_view = false)
    return if not @rep
    
    prompts = []
    values = []

    # Get the camera attributes
    camera = self.get_camera
    return if not camera
    
    # Get the camera name
    name = self.name
    name = "" if not name
    prompts.push "Name"
    values.push name
    
    # Get the height of the camera above z=0
    h = self.height
    prompts.push "Height"
    values.push h
    
    # Get the tilt angle
    angle = self.tilt.radians
    prompts.push "Tilt"
    tilt = format "%.1f degrees", angle
    values.push tilt
    
    # Get the focal length
    fl = camera.focal_length
    prompts.push "Focal length"
    fl = format "%.0f mm", fl
    values.push fl
    
    # Get the aspect ratio
    ar = camera.aspect_ratio
    prompts.push "Aspect Ratio"
    values.push ar

    # Show the dialog
    results = inputbox prompts, values, "Camera Properties"
    
    # Update any values that were changed
    return if not results
    camera_changed = false
    
    model = @rep.model
    
    if name && results[0] != name
        name = results[0]
    else
        name = nil
    end

    if( h != results[1] )
        h = results[1]
        self.set_height h
        camera_changed = true
    end

    if( tilt != results[2] )
        angle = results[2].to_f
        self.set_tilt(angle.degrees)
        camera_changed = true
    end
    
    camera = self.get_camera if camera_changed
    
    if( fl != results[3] )
        fl = results[3].to_f
        camera.focal_length = fl
        camera_changed = true
    end
    
    if( ar && ar != results[4] )
        ar = results[4]
        camera.aspect_ratio = ar
        camera_changed = true
    end
    
    if( camera_changed )
        self.set_attributes(camera, name)
        if( update_view )
            view = model.active_view
            if( view )
                view.camera = camera, 0.5
            end
        end
    elsif name
        self.name = name
    end
    
end

#-------------------------------------
# class methods

# Create camera geometry from the current active view
def CameraRep.create_from_active_view
    model = Sketchup.active_model
    return if not model
    view = model.active_view
    return if not view
    rep = CameraRep.new view
    
    # Activate the newly created camera
    model.select_tool(CameraTool.new(rep.geometry)) if rep
end

# Get the selected camera (or nil)
def CameraRep.selected_camera
    model = Sketchup.active_model
    return nil if not model
    ss = model.selection
    return nil if ss.count != 1
    entity = ss.first
    return nil if not entity.has_attributes? "camera"
    entity
end

def CameraRep.selected_camera_rep
    entity = CameraRep.selected_camera
    return nil if not entity
    CameraRep.new entity
end

# Activate a selected camera
def CameraRep.activate_selected_camera
    rep = CameraRep.selected_camera_rep
    rep.activate if rep
end

def CameraRep.validate_activate_camera
    camera = CameraRep.selected_camera
    return MF_GRAYED if not camera
    MF_ENABLED    
end

# Show the properties of the selected camera
def CameraRep.edit_selected_camera
    rep = CameraRep.selected_camera_rep
    rep.edit if rep
end

# determine if a single camera is selected
def CameraRep.camera_selected?
    ss = Sketchup.active_model.selection
    return false if ss.count != 1
    ss.first.has_attributes? "camera"
end

# Find all cameras in the model
def CameraRep.cameras_in_model(model)
    cameras = model.entities.select {|e|
        (e.kind_of?(Sketchup::Group) || e.kind_of?(Sketchup::ComponentInstance)) &&
        e.has_attributes?("camera")
    }
    cameras
end

# Select a camera by name
def CameraRep.select_camera
    if( CameraRep.camera_selected? )
        CameraRep.activate_selected_camera
        return
    end
    
    model = Sketchup.active_model
    cameras = CameraRep.cameras_in_model model
    if( cameras.length < 1 )
        UI.messagebox "No Cameras are defined"
        return
    end
    
    prompts = ["Camera_Name"]
    names = cameras.collect {|c| c.get_attribute("camera","name", "")}
    values = nil
    if( @@last_selected_name )
        i = names.index @@last_selected_name
        values = [names[i]] if i
    end
    values = [names[0]] if not values
    popups = [names.join("|")]
    results = inputbox prompts, values, popups, "Select Camera"
    return if not results
    
    i = names.index results[0]
    if( not i )
        UI.beep
        return
    end
    @@last_selected_name = names[i]
    rep = CameraRep.new cameras[i]
    rep.activate
end

# Hide all cameras
def CameraRep.hide
    layer = Sketchup.active_model.layers["Cameras"]
    layer.visible=false if layer
end

# Show all cameras
def CameraRep.show
    layer = Sketchup.active_model.layers["Cameras"]
    layer.visible=true if layer
end

# Go to a top view and zoom extents so that we can see all cameras
def CameraRep.show_all
    # make sure that the layer isn't hidden
    CameraRep.show
    
    # Now go to a top view and zoom extents
    view = Sketchup.active_model.active_view
    camera = view.camera
    dist = camera.eye.distance(camera.target)
    eye = camera.target + [0,0,dist]
    up = [0,1,0]
    camera.set eye, camera.target, up
    view.zoom_extents
end

end # class CameraRep

#=============================================================================
# Add a copy method to the Sketchup::Camera class
# NOTE: This method should really be called clone and should be implemented
# by the class itself.  It is not implemented in SketchUp 4.0 though.  I'm
# calling it copy here so that it won't conflict with a clone method
# when one is added in a later release.
class Sketchup::Camera

# Create a copy of a Camera
def copy
    # Create the new camera
    value = self.perspective? ? self.fov : self.height
    camera = Sketchup::Camera.new self.eye, self.target, self.up, self.perspective?, value
    
    # set the other values that can't be set on the new method
    camera.aspect_ratio = self.aspect_ratio
    camera.image_width = self.image_width
    camera.description = self.description
    
    camera
end

end # class Sketchup::Camera

#=============================================================================
# A special camera tool that behaves more like a real camera and also updates
# the position of a selected camera as it is moved.

class CameraTool

@@speed = 1.0

def initialize(*args)
    if( args != nil && args.length > 0 ) 
        @rep = CameraRep.new args[0]
    else
        @rep = nil
    end
end

def camerarep
    @rep
end

def activate
    @modifiers = 0
    @keys = 0
    self.show_prompt
    @down_point = nil
    @drawn = false
    @speedx = @@speed
    @speedy = @@speed
    
    Sketchup.set_status_text "Height", SB_VCB_LABEL
    self.show_height
end

def deactivate(view)
    view.invalidate if @drawn
end

def resume(view)
    # The resume method is called when the tool becomes active again after
    # a pushed tool was popped.  This almost always means that the user
    # used one of the other view tools.  For example, they were probably
    # orbitting with the middle mouse button.  There is currently no
    # way to keep the camera rep in synch with the view camera when using
    # a different camera tool, but this method will let us re-synchronize
    # when we get control back
    @rep.update(view.camera) if @rep

    self.show_prompt
    Sketchup.set_status_text "Height", SB_VCB_LABEL
    self.show_height
end

# Show the prompt for the current mode
def show_prompt
    if( @modifiers == 0 )
        Sketchup.set_status_text "Pan/Dolly", SB_PROMPT
    elsif( @modifiers & CONSTRAIN_MODIFIER_MASK != 0 )
        Sketchup.set_status_text "Truck/Pedestal", SB_PROMPT
    elsif( @modifiers & COPY_MODIFIER_MASK != 0 )
        Sketchup.set_status_text "Pan/Tilt", SB_PROMPT
    end
end

def show_height
    return if not @rep
    
    h = @rep.height.to_s
    Sketchup.set_status_text h, SB_VCB_VALUE
end

# Set the modifier key flags that we are interested in
def set_flags(flags)
    @modifiers = flags & (MK_SHIFT | MK_CONTROL | MK_ALT | MK_COMMAND)
    self.show_prompt
end

# The standard guess_target method on View can be really slow
# so I am using this alternate version
def guess_target_distance(view, pt = nil)
    # if no point is given use the view center
    pt = view.center if not pt
    
    # first try to get a point in the model
    distance = nil
    ip = view.inputpoint pt.x, pt.y
    if( ip )
        distance = view.camera.eye.distance ip.position if ip
        # if we picked on an entity, then use that distance
        return distance if( ip.face or ip.edge or ip.vertex )
    else
        distance = view.model.bounds.diagonal
    end
    
    # We didn't pick a point on the model.  # Try looking at the model bounds
    bb = view.model.bounds
    eye = view.camera.eye
    dir = view.camera.direction
    total = 0.0
    n = 0
    for i in (0..7) do
        pt = bb.corner i
        vec = pt - eye
        d = vec % dir
        if( d > 0.0 )
            total += d
            n += 1
        end
    end
    
    # Use the average distance of the corners of the model
    # bounds that are in front of the camera
    distance = (total / n).to_l if n > 0
    
    distance
end

# Start an animation when one of the arrow keys is pressed
def onKeyDown(key, repeat, flags, view)
    #puts "onKeyDown: #{key}, #{flags}"
    return if repeat > 1
    self.set_flags flags
    
    case( key )
    when VK_LEFT
        @keys |= LEFT_ARROW
    when VK_RIGHT
        @keys |= RIGHT_ARROW
    when VK_UP
        @keys |= UP_ARROW
    when VK_DOWN
        @keys |= DOWN_ARROW
    when '+'[0]
        @@speed += 1.0
    when '-'[0]
        @@speed -= 1.0
        @@speed = 1.0 if @@speed < 1.0
    else
        return
    end
    @speedx = @@speed
    @speedy = @@speed
    
    # get the distance from the camera to what we are looking at to control the speed
    @distance_to_target = self.guess_target_distance view
    
    view.animation = self
    view.dynamic = 3
end

def onKeyUp(key, repeat, flags, view)
    #puts "onKeyUp: #{key}, #{flags}"
    self.set_flags flags
    
    case( key )
    when VK_LEFT
        @keys &= ~LEFT_ARROW
    when VK_RIGHT
        @keys &= ~RIGHT_ARROW
    when VK_UP
        @keys &= ~UP_ARROW
    when VK_DOWN
        @keys &= ~DOWN_ARROW
    when VK_COMMAND
        # When the command key is pressed on the Mac, we don't see a key up
        # event so the animation gets stuck.  We don't really know which key
        # to clear in this case, so just clear all keys to stop the animation.
        @keys = 0
    else
        return
    end
    
    if( @keys == 0 )
        view.animation = nil
        view.dynamic = false
    end
end

def onLButtonDown(flags, x, y, view)
    # disable autopan
    if view.respond_to? :enable_autopan=
        view.enable_autopan = false
    end
    @down_point = [x, y]
    @distance_to_target = self.guess_target_distance view, @down_point
    
    view.animation = self
    view.dynamic = 3
end

def onLButtonUp(flags, x, y, view)
    if view.respond_to? :enable_autopan=
        view.enable_autopan = true
    end
    @down_point = nil
    @keys = 0
    view.animation = nil
    view.dynamic = false
    view.invalidate if @drawn
end

def onLButtonDoubleClick(flags, x, y, view)
    # Get the new view direction
    ray = view.pickray(x,y)
    dir = ray[1]

    # If I just change the direction of the view's camera, it will
    # update the view right away.  I want to have a transition to the
    # new direction, so I need to create a copy of the camera.
    camera = view.camera.copy
    eye = camera.eye
    target = camera.target
    up = camera.up
    dist = eye.distance target
    target = eye.offset dir, dist
    camera.set eye, target, up

    # Update the position of the camera rep
    @rep.update camera if @rep
    
    # Now update the view's camera from this one with a transition
    view.camera = camera, 0.5
end

def onMouseMove(flags, x, y, view)
    return if not @down_point
    
    # simulate the arrow keys
    @keys = 0
    dx = x - @down_point.x
    if( dx > 10 )
        @keys |= RIGHT_ARROW
    elsif( dx < -10 )
        @keys |= LEFT_ARROW
    end
    
    # compute speed factor
    @speedx = (dx.abs * 4.0)/view.vpwidth
    
    dy = y - @down_point.y
    if( dy > 20 )
        @keys |= DOWN_ARROW
    elsif( dy < -20 )
        @keys |= UP_ARROW
    end
    
    # compute speed factor in the y direction
    @speedy = (dy.abs * 4.0)/view.vpheight
    
end

def onUserText(text, view)
    # The user can type in the camera height
    begin
        height = text.to_l
        if( @rep )
            @rep.set_height(height, view)
            self.show_height
        end
    rescue
        puts "Bad height string entered (#{text})"
    end
end

def draw(view)
    @drawn = false
    return if not @down_point
    
    # Draw a '+' at the mouse down point
    x = @down_point.x
    y = @down_point.y
    view.drawing_color = 0
    view.draw2d GL_LINES, [x, y-10], [x, y+10] # There seems to be a bug in draw2d!
    view.draw2d GL_LINES, [x-10, y], [x+10, y], [x, y-10], [x, y+10]
    
    @drawn = true
end

# Get the id of the method to call when the left or right key is down
def lr_function
    f = :pan
    case @modifiers
    when CONSTRAIN_MODIFIER_MASK
        f = :truck
    when COPY_MODIFIER_MASK
        f = :pan
    end
    f
end

# Get the id of the method to call when the left or right key is down
def ud_function
    f = :dolly
    case @modifiers
    when CONSTRAIN_MODIFIER_MASK
        f = :pedestal
    when COPY_MODIFIER_MASK
        f = :tilt
    end
    f
end

# Move the camera.  This is used by dolly, truck and pedestal
def move(view, time, direction, speed)
    # compute how far to move
    distance = @distance_to_target * time / 5.0
    distance *= speed
    
    vec = direction
    return if( vec.length == 0.0 )
    vec.length = distance
    
    # now move the camera
    camera = view.camera
    eye = camera.eye
    target = camera.target
    up = camera.up
    
    eye.offset! vec
    target.offset! vec

    camera.set(eye, target, up)
end

# dolly moves the camera in the direction it is pointing but keeping
# the height constant
def dolly(view, time)
    # compute the direction to move in.  We want to move in the direction
    # that the camera is pointing but keeping the height constant
    direction = view.camera.direction
    direction.z = 0.0
    
    # see if we need to reverse it
    direction.reverse! if( (@keys & DOWN_ARROW) != 0 )

    # now move the camera
    self.move(view, time, direction, @speedy)
end

# move left or right perpendicular to the camera direction
def truck(view, time)
    direction = view.camera.direction * Z_AXIS
    direction.reverse! if( (@keys & LEFT_ARROW) != 0 )
    self.move(view, time, direction, @speedx)
end

# move up or down
def pedestal(view, time)
    direction = Geom::Vector3d.new(0,0,1)
    direction.reverse! if( (@keys & DOWN_ARROW) != 0 )
    self.move(view, time, direction, @speedy)
end

# turn the camera - used for pan and tilt
def turn(view, time, axis, speed)
    # We want it to take 20 seconds for a full revolution
    return if( time >= 20.0)
    angle = Math::PI * time / 10.0
    angle *= speed

    # Create a transformation to rotate about axis through the eye position
    camera = view.camera
    eye = camera.eye
    target = camera.target
    up = camera.up
    t = Geom::Transformation.rotation(eye, axis, angle)
    target.transform! t
    up.transform! t
    camera.set eye, target, up
end

def pan(view, time)
    axis = Geom::Vector3d.new 0, 0, 1
    axis.reverse! if( (@keys & RIGHT_ARROW) != 0 )
    self.turn(view, time, axis, @speedx)
end

def tilt(view, time)
    axis = view.camera.direction * Z_AXIS
    axis.reverse! if( (@keys & DOWN_ARROW) != 0 )
    self.turn(view, time, axis, @speedy)
end

# The CameraTool also acts as an animation so that it can "walk" when you hold
# down the arrow keys
def nextFrame(view)
    # Compute how long it took to display the last frame.  This will
    # be used to compute how much to move or turnfor the next frame.
    time = view.last_refresh_time
    time_delay = 0
    if( time < 0.04 )
        time_delay = 0.04 - time
        time = 0.04
    end
    
    if( (@keys & (LEFT_ARROW | RIGHT_ARROW)) != 0 )
        self.send(self.lr_function, view, time)
    end
    if( (@keys & (UP_ARROW | DOWN_ARROW)) != 0 )
        self.send(self.ud_function, view, time)
    end
    
    # update the camera parameters
    @rep.update(view.camera) if @rep

    view.show_frame time_delay
    self.show_height
    
    true
end

# Get the model for the tool.
# REVIEW: I should probably derive Ruby Tools from some tool that I create
# in SketchUp and have this be a method of the base class.  I can't get
# this information directoy from the Ruby interface now, so I have to infer
# it from the camera rep
def model
    return Sketchup.active_model if not @rep
    @rep.model
end

def view
    model = self.model
    return nil if not model
    model.active_view
end

# End the tool
def done
    model = self.model
    model.select_tool(nil) if model
end

# Edit the current camera
def edit
    if( not @rep )
        UI.beep
        return
    end
    @rep.edit true
    self.show_height
end

# Reset the tilt to 0 degrees on the current camera
def reset_tilt
    if( not @rep )
        # TODO we can activate the camera without having a camera rep
        # I need to add methods to just reset the view camera in this case
        UI.beep
        return
    end
    @rep.set_tilt 0.0, self.view
end

# Context menu for the camera tool
def getMenu(menu)
    menu.add_item("Done") {self.done}
    menu.add_item("Edit Camera...") {self.edit}
    menu.add_item("Reset Tilt") {self.reset_tilt}
end

end # class CameraTool

#=============================================================================
# Read cameras from a file

module Previs

def Previs.select_camera(index)
    #puts "select camera #{index}"
    camera_data = $cameras[index]
    return if not camera_data
    
    model = Sketchup.active_model
    return if not model
    view = model.active_view
    return if not view
    camera = view.camera
    
    # Set all of the values that can be set
    camera_data.each  do |key, value|
    
        # See if this is an attribute that we can set
        cmd = key + "="
        if( camera.respond_to? cmd )
            #puts "#{cmd} #{value}"
            camera.send cmd, value
        end
    end
end

def Previs.read_cameras
    $cameras = []
    camera_menu = nil
    
    # first find the camera definition file
    camera_file_name = Sketchup.find_support_file "cameras.txt", "plugins/previs"
    if( not camera_file_name )
        puts "Could not find camera file\n"
        return
    end

    # parse the cameras file
    camera_data = nil
    IO.foreach(camera_file_name) do |line|
        next if line =~ /^\s*#/ # skip comments
        line.chomp!
        next if not line =~ /\s*(\w*)\s*=\s*(.*)/
        
        v = eval $2
        if( $1 == "name" )
            index = $cameras.length
            camera_data = []
            $cameras.push camera_data

            if( not camera_menu )
                camera_menu = UI.menu("Camera").add_submenu("Select Camera Type")
            end
            camera_menu.add_item(v) { Previs.select_camera index }
            
        end
        camera_data.push([$1, v])
    end
    
    $cameras.length
end

def Previs.add_help_menu
    help_file = Sketchup.find_support_file "previs_help.html", "plugins/previs"
    if( help_file )
        helpurl = "file://" + help_file
        UI.menu("Help").add_item("Previs Help") {UI.openURL(helpurl)}
    else
        puts "Cannot find help file"
    end
end

end # module Previs

#=============================================================================

# Add some menu items
if( not file_loaded?("camera.rb") )

    # Constants used to determine the keys pressed in the CameraTool
    LEFT_ARROW  = 1
    RIGHT_ARROW = 2
    UP_ARROW    = 4
    DOWN_ARROW  = 8

    add_separator_to_menu("Camera")
    camera_menu = UI.menu("Camera")
    camera_menu.add_item("Create Camera") { CameraRep.create_from_active_view }
    camera_menu.add_item("Look Through Camera") { CameraRep.select_camera }
    camera_menu.add_item("Show All") { CameraRep.show_all }
    
    # Create a sub-menu with standard cameras
    Previs.read_cameras
    
    # Add a menu choice for help
    Previs.add_help_menu

    # Add a context menu handler that will add a menu choice to a context menu
    # for a camera
    UI.add_context_menu_handler do |menu|
        if( CameraRep.camera_selected? )
            menu.add_separator
            menu.add_item("Look Through Camera") { CameraRep.activate_selected_camera }
            menu.add_item("Edit Camera...") { CameraRep.edit_selected_camera }
        end
    end

    file_loaded("camera.rb")
end
