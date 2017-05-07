Modeule JRM
  mod = Sketchup.active_model # Open model
  ent = mod.entities # All entities in model
  sel = mod.selection # Current selection
  view = mod.active_view



  desktop = ENV["USERPROFILE"] || ENV["HOME"]
  newdirectory = "New folder"
  imageName = "testImage"
  i=0
  outpath = "#{desktop}/#{newdirectory}/#{imageName}#{i}.png"




  view.refresh
  Kernel.sleep(0.5)
  view.write_image "C:/Users/12372/Desktop/New folder/testImage#{i}.png"




  # Ruby Script for Retexturing and Rendering Scene from source directory images.
  # Have top of board game/material selected (Just the top face) before running script.
  inputDir = Dir.open "C:/Users/XXXX/Downloads/Notes And Things/Photo_Illustrator_OddandEnds/SketchUp/Gameboard Modeling/TopCovers(Bulk)"
  i = 1
  inputDir.each do |file|
  # Process through Sketchup.
  # Get a handle to the selection set.
  currentMaterial = Sketchup.active_model.materials.current
  currentMaterial.texture = File.absolute_path file
  UI.messagebox(file)
  # Save Render to outputDir.
  view = Sketchup.active_model.active_view
  view.write_image "C:/Users/XXX/Downloads/Notes And Things/Photo_Illustrator_OddandEnds/SketchUp/Gameboard Modeling/Renders/BulkOutput/testImage#{i}.png"
  i = i + 1
  end


  model = Sketchup.active_model
  matls = model.materials
  matl = matls["SomeName"]
  matls.current= matl unless matl.nil?

  ss = model.selection
  face = ss.grep(Sketchup::Face).first
  unless face.nil?
    matl = face.material
  end

  if ss.single_object?
    obj = ss[0]
    if obj.is_a?(Sketchup::ComponentInstance) || obj.is_a?(Sketchup::Group)
      ents = obj.definition.entities
      face = ents.grep(Sketchup::Face).first
      matl = face.material
    end
  end




  userhome = ENV["USERPROFILE"] || ENV["HOME"]
  gameboard = "Downloads/Notes And Things/Photo_Illustrator_OddandEnds/SketchUp/Gameboard Modeling"
  imgpath = "#{userhome}/#{gameboard}/TopCovers(Bulk)"

  Dir::chdir(imgpath) {
    textures = Dir["TestBoardTop*.png"].sort!
  }
  # back in previous dir

  render = "/Renders/BulkOutput"
  outpath = "#{userhome}/#{gameboard}/#{render}"

  output = ""
  textures.each_with_index do |file,i|
    #
    while i > 0 && !output.empty? && !File.exist?(output)
      Kernel.sleep(0.5)
    end
    output = "#{outpath}/testImage#{i}.png"
    #
    material.texture = "#{imgpath}/#{file}"
    view.refresh
    Kernel.sleep(0.5) # give SketchUp time to refresh the view
    view.write_image( output )
    #
  end
end
