
require 'sketchup.rb'
###
module JRM


def self.import_skp()
  ###

  def self.get_file()
	    msg="Import SKP..."
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
  			  fil=fil.force_encoding("UTF-8")
  		    end
  			next unless File.extname(fil).downcase == type
  			list << file
  		}
	    return list
  end#def





  ###
  def self.as_list(file0, type)
      list0=[]
      list0 << file0
      return list0










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
	    model.start_operation("Import SKP", true)
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
		UI.messagebox("Import Completed 2.")
	    Sketchup.send_action("selectSelectionTool:")
	    return nil
	  end#def




  ###
  @file=self.get_file()
  return nil if not @file
  @folder=self.get_folder(@file)
  @type=self.get_type(@file)
  @list=self.as_list(@file, @type)
  self.import(@type, @list)
  ###


end#def import_skp

end#module
###
