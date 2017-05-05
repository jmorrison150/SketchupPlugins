require 'sketchup.rb'
require 'extensions.rb'

module JRM
  module CustomTool

    unless file_loaded?(__FILE__)
      ex = SketchupExtension.new('sketchupPlugins', 'jm_sketchupPlugins/main')
      ex.description = 'SketchUp Plugins.'
      ex.version     = '0.0.2'
      ex.copyright   = 'JRM 2017'
      ex.creator     = 'JRM'
      Sketchup.register_extension(ex, true)
      file_loaded(__FILE__)
    end

  end # module CustomTool
end # module Examples
