desktop = ENV["USERPROFILE"] || ENV["HOME"]
newdirectory = "New folder"
outpath = "#{desktop}/#{newdirectory}/#{imageName}#{i}.png"


buildings = Dir.glob("#{dir}/".skp)
buildings.each do |building|
    Sketchup.file_new
    model = Sketchup.active_model
    model.import building
    model.entities.each do |e|
      if e.class == Sketchup::ComponentInstance
        e.explode
      end
    end

    unfold(model.entities)
    Sketchup.send_action "viewTop:"
    view = model.active_view
    view.zoom_extents

    save_name = "name"
    view.write_image outpath
  end
  
