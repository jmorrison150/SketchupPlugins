module JRM


	file_loaded(__FILE__) ###

def self.pushRandom
	model = Sketchup.active_model
	selection = model.selection.to_a
	faces = selection.grep(Sketchup::Face)


	faces.each do |face|
		face.pushpull(rand(20))
	end
end#pushpull

### menu
unless file_loaded?(__FILE__) ### so only get menu item once...
    UI.menu("Draw").add_item("push Random"){self.pushRandom()} ###
end#if ###

end#module
