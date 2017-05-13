require 'sketchup.rb'

module JRM
	def self.pushRandom
		model = Sketchup.active_model
		selection = model.selection.to_a
		faces = selection.grep(Sketchup::Face)
		faces.each do |face|
			face.pushpull(rand(200))
		end#each
	end#def

	#TODO
	def default_variables
		[Slider.new("Push", 0.5.feet, 10.feet, 2.feet),
			Slider.new("Height", 2.feet, 12.feet, 4.feet)
		]
	end

	#TODO
	def create_entities(data, container)
		model = Sketchup.active_model
		selection = model.selection.to_a
		faces = selection.grep(Sketchup::Face)
		faces.each do |face|
			face.pushpull(rand(200))
		end#each
		container.add_item(faces)
	end

	#TODO
	def default_parameters
	end

	#TODO
	def translate_key(key)
	end
end#module
