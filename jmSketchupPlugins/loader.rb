# Licensed under the MIT license

  require 'sketchup.rb'
  require 'pushRandom.rb'
  require 'importSkp.rb'
  require 'main.rb'

module JRM


  ### menu
  unless file_loaded?(__FILE__) ### so only get menu item once...
    UI.menu("File").add_item("Import SKP"){JRM.import_skp()} ###

  	submenu=UI.menu("Plugins").add_sub_menu("SketchupPlugins")
  	submenu.add_item("push Random"){JRM.pushRandom()}
    submenu.add_item("importSkp"){JRM.importSkp}

  end#unless ###

  file_loaded(__FILE__) ###


end # module Examples
