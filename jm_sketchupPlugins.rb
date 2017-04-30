require 'sketchup.rb'
require 'extensions.rb'

jm_extension = SketchupExtension.new "Sketchup Plugins", "jm_sketchupPlugins/loader"
jm_extension.version = '0.0.1'
jm_extension.copyright = "JRM 2017"
jm_extension.description = "Sketchup Plugins"
jm_extension.creator = "JRM"
result = Sketchup.register_extension jm_extension, true
