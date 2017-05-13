module JRM
  def self.renderFolder()
    ###

      def self.get_file()
    	    msg="Render all in Folder: select file..."
    	    Sketchup::set_status_text(msg)
    	    file = UI.openpanel(msg, "", "")
    	    unless file
    	      puts "IMPORT - CANCELED."
    	      Sketchup.send_action("selectSelectionTool:")
    	      return nil
    	    else
    	      file = file.tr("\\","/")
    		  if defined?(Encoding)
    			     file=file.force_encoding("UTF-8")
    		  end
    	      return file
    	    end#if
      end#def
      ###

    desktop = ENV["USERPROFILE"] || ENV["HOME"]
    newFolder = "New folder"
    file1 = self.get_file()
    folder=File.dirname(file1)
    files = Dir.glob("#{folder}/**/*.skp")
    files.each do |f|
      Sketchup.open_file(f)
      model = Sketchup.active_model
      view = model.active_view
      pages = model.pages
      filesName = f.to_s


      pages.each do |page|
        pageName = page.name
        view.camera = page.camera
        view.refresh
        Kernel.sleep(0.5)
        outpath = "#{desktop}/#{newFolder}/#{filesName}#{i}-#{pageName}.png"
        view.write_image(outpath)


      end #each page
    end #each file
  end #def renderFolder
end #Module
