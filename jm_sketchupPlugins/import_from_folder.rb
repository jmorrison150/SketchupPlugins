=begin
(c) TIG 2009-2015

import_from_folder.rb

Run the tool by typing
  TIG::import_from_folder
in the Ruby Console or picking 'Import ALL from Folder' from the File menu.
In the dialog that appears navigate to the required Folder and pick one 
File of the 'type' to be imported.
e.g. select any 'geometry' type [some are available for 'Pro' only]
  skp, dwg, dxf, kml, dae, 2ds, dem, ddf
or image files
  png, jpg, tif, psd, tga, bmp
Images are 'imported' differently...  They come in with their width/height 
in inches based on their pixel-size, and they line up along X-axis [red]
ALL files of the 'type' you selected will be imported from that folder 
into the Model.
SKPs produce an extra request on 'placement'...
Progress of each file is shown in the VCB...
A report TXT file is written in the chosen folder.

v1.0 20091124 First issue.
v1.1 20100305 Image 'import' added.
v1.2 20110529 Module added.
v1.3 20140116 STL files import added, uses last set options, need to OK each one.
v1.4 20150124 Overhauled for newer SUp versions.
v1.5 20150124 UTF-8 encoding forced to file names in >=v2014.
v1.6 20150201 Multiple SKP import glitches [when unpurged etc] fixed.
=end
### 
require 'sketchup.rb'
###
module JRM


file_loaded(__FILE__) ###

def self.import_from_folder()
  ###
	  def self.get_file()
	    msg="Import ALL Files: Choose TYPE..."
	    Sketchup::set_status_text(msg)
	    file = UI.openpanel(msg, "", "")
	    unless file
	      puts "IMPORT ALL - CANCELED."
	      Sketchup.send_action("selectSelectionTool:")
	      return nil
	    else
	      file = file.tr("\\","/")
		  if defined?(Encoding)
			file=file.force_encoding("UTF-8") ### v2014 lashup
		  end
	      return file
	    end#if
	  end
  ###
  def self.get_folder(file)
    folder=File.dirname(file)
    return folder
  end#def
  ###
  def self.get_type(file)
    type=File.extname(file).downcase
    return type
  end#def
  ###
  def self.get_list(folder, type)
    list=[]
    Dir.foreach(folder){|file|
		fil = File.join(folder, file)
		if defined?(Encoding)
		  fil=fil.force_encoding("UTF-8") ### v2014 lashup
	    end
		next unless File.extname(fil).downcase == type
		list << fil
	}
    return list
  end#def
  ###
	def self.import(type, list)
	###
	rep=File.join(@folder, "import_report.txt")
	fil=File.open(rep, 'w')
	fil.puts(type)
	fil.puts(list)
	fil.puts()
	fil.puts(rep)
	fil.puts()
	fil.close
	#return
    ### check for images
    pt=ORIGIN.clone
    imgs=[".png", ".jpg", ".tif", ".psd", ".tga", ".bmp"]
    if imgs.include?(type)
      image=true
    else
      image=false
    end#if
    model=Sketchup.active_model
    model.start_operation("Import ALL from Folder", true)
	defsIN=model.definitions.to_a ###
	###
	if type == ".skp"
		compos=[]
		skp=true
		tr=Geom::Transformation.new()
		#UI.beep
		#ync=UI.messagebox("Place #{list.length} Imported 'SKP' Components at [0,0,0] ?\n\nYes:\tPlace them ALL\nNo:\tLeave them only as Component-Definitions\nCancel:\tAbort !", MB_YESNOCANCEL,"")
		ync=6
		if ync == 6 ### 6=YES 7=NO 2=CANCEL
			place=true
		elsif  ync == 2
			return nil
		else ### 7 No
			place=false
		end#if
	else
		skp=false
	end
	###
	list.each_with_index{|f, ix|
	  fil=File.open(rep, 'a')
      Sketchup::set_status_text("Importing "+File.basename(f)+" - #{ix+1}/#{list.length}")
      if image
	    begin
			fil.puts('importing '+f)
			fil.close
			img = model.active_entities.add_image(f, pt, 100)
			pxw=img.pixelwidth
			pxh=img.pixelheight
			img.size = pxw, pxh
			pt=Geom::Point3d.new(pt.x+pxw, 0, 0)
			### all images go in a line, in X axis
		rescue Exception => e
			fil.puts(e)
			fil.close
		end
	  elsif skp
		defn = model.definitions.load(f)
		if defn
			defsIN << defn
			compos << model.active_entities.add_instance(defn, tr) if place
			fil.puts('done')
		else			
			fil.puts('failed')
		end
		fil.close
      else ### other type
        begin
			fil.puts('importing '+f)
			###
			status=model.import(f, false)
			###
			if status
				fil.puts('done')
			else			
				fil.puts('failed')
			end
			fil.close
		rescue Exception => e
			fil.puts(e)
			fil.close
		end
      end#if
    }
	begin
		fil.close
	rescue
	end
	### closing tidy up
	if skp
		model.definitions.each{|d|
			next if d.instances[0] ### used
			next if defsIN.include?(d) ### used if 'place'
			d.entities.clear! ### unpurged unused dross from the imported SKP
		}
		compos.each{|ins| ins.erase! if ins.valid? } unless place
	end
	###
    model.commit_operation
	model.active_view.refresh
	UI.messagebox("Import Completed.")
    Sketchup.send_action("selectSelectionTool:")
    return nil
  end#def
  ###
  @file=self.get_file()
  return nil if not @file
  @folder=self.get_folder(@file)
  @type=self.get_type(@file)
  @list=self.get_list(@folder, @type)
  self.import(@type, @list)
  ###
end#def import_from_folder

### menu
unless file_loaded?(__FILE__) ### so only get menu item once...
    UI.menu("File").add_item("Import ALL from Folder"){self.import_from_folder()} ###
end#if ###

end#module
###

