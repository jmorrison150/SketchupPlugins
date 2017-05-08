# Licensed under the MIT license

  require 'sketchup.rb'
  require_relative 'importSkp.rb'
  require_relative 'lineTool.rb'
  require_relative 'pushRandom.rb'

module JRM


  ### menu
  unless file_loaded?(__FILE__) ### so only get menu item once...
    UI.menu("File").add_item("Import SKP"){JRM::import_skp()} ###

  	submenu=UI.menu("Plugins").add_submenu("SketchupPlugins")
    	submenu.add_item("push Random"){JRM::pushRandom()}
      submenu.add_item("import Skp"){JRM::import_skp()}
      submenu.add_item("line Tool"){JRM::activate_line_tool()}
  end#unless ###

#  file_loaded(__FILE__) ###


end # module Examples
