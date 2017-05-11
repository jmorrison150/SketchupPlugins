# Licensed under the MIT license

  require 'sketchup.rb'
#  require_relative 'importSkp.rb'
#  require_relative 'lineTool.rb'
#  require_relative 'pushRandom.rb'


  require_all(File.dirname(__FILE__))
#  require_all (File.Join(File.dirname(__FILE__),'/LiveParametric/VariableDicts/'))
#  require_all (File.Join(File.dirname(__FILE__),'/LiveParametric'))
#  require_all (File.Join(File.dirname(__FILE__),'/LiveParametric/LP Models'))
#  require_all './LiveParametric/images/'
#  require_all './LiveParametric/javascripts/'
#  require_all('./')
#  require_all('')
#  require_all()

curDir = File.dirname(__FILE__)

def require_recursive( topDir)
	# puts "require_recursive called on #{topDir}"
	return nil unless File.directory?(topDir)

	$: << topDir
	subdirs = Dir.entries(topDir).map{|d|
			# don't include any directories starting with .
		 	next if d[0,1] == '.'
			fullDir = File.join(topDir,d)
			fullDir if File.directory?(fullDir)
	}.compact

	# puts "Subdirs:\n\t"+subdirs.join("\n\t") if subdirs.length >0

	subdirs.each{|d| require_recursive(d)} if subdirs.length > 0

	 rbFiles = Dir[File.join(topDir, "*.rb")]
	 rbFiles.each {|e| require e }	if rbFiles.length > 0
end

require_recursive( File.join(curDir, "LiveParametric"))





module JRM


  ### menu
  unless file_loaded?(__FILE__) ### so only get menu item once...
    UI.menu("File").add_item("Import SKP 4"){JRM::import_skp()} ###

  	submenu=UI.menu("Plugins").add_submenu("SketchupPlugins")
    	submenu.add_item("push Random"){JRM::pushRandom()}
      submenu.add_item("import Skp"){JRM::import_skp()}
      submenu.add_item("line Tool"){JRM::activate_line_tool()}
      submenu.add_item("Onion Dome LP"){OnionDomeLP.new}
      submenu.add_item("Moving circles"){MovingCircles.new}


  end#unless ###

#  file_loaded(__FILE__) ###


end # module Examples
