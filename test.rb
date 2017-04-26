point1 = [0,0,0]
point2 = [100,100,100]
model = Sketchup.active_model
entities = model.active_entities
entities.add_edges(point1,point2)

point = Geom::Point3d.new 0,0,0
transform = Geom::Transformation.new point
model = Sketchup.active_model
entities = model.active_entities
#TODO relative path



path = Sketchup.find_support_file "Bed.skp",
  "Components/Components Sampler/"
definitions = model.definitions
componentdefinition = definitions.load path
instance = entities.add_instance componentdefinition, transform
point = componentdefinition.insertion_point


 # the user need to select only one of the dwg file 
    filename = UI.openpanel "Import skp", "", "*.skp" 
    return false if filename == nil 
    path= File.dirname(filename) 
    return false if not path 
    path.gsub!("\\", "/") 
    Dir.chdir(path) 
    skpnames = Dir.glob("*.{skp}") 
    model = Sketchup.active_model 
    for i in 0..skpnames.length-1 
        model.import path + '/' + skpnames[i] 
    end



#get all skp files in folder

#each
	#import skp to component definition
	#TODO render all views
	#TODO remove instance; remove componentdefinition
