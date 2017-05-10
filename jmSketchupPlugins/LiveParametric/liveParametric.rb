
require 'parametric'
require 'LiveParametricHTMLWriter.rb'
require 'ParameterDict.rb'

include EJ
# TODO: make sure all VariableDict classes are loaded here, so all subclasses of 
# LiveParametric have access to them without specifically requiring them
class LiveParametric < Parametric
    @@current_instances = {}

    # Initialize
    def initialize(*args)
        data = args[0]
        
        if not data
 
            @dict = self.default_dict
            super(data)
            @dialog_open = false
            @dict.update( "dialog_open", @dialog_open)
            set_attributes( @dict.to_h)
            Sketchup.file_new if not Sketchup.active_model
            # Launch the WebDialog to control the app
            launchWebDialog()

            ## THIS would be good to encapsulate here, but we need to know
            # the file the subclass is defined in.  Instead, addToPluginsMenu
            # is called in create_entities -- ETJ 29-Jun-2007
            # self.addToPluginsMenu
        elsif data.kind_of? Sketchup::Entity
            # get a dictionary from the entity
            @entity = data
            @dict = parameterDictFromEntity(@entity)
            # Check with @entity to see if dialog_open is true
            @dialog_open = @dict.to_h["dialog_open"]
            
            launchWebDialog
        end
    end

    def parameterDictFromEntity( entity)
        d = default_dict
        LiveParametric.parameters(entity).each_pair { |key, val| d.update(key, val) }
        d
    end
    
    def LiveParametric.parameters(entity, create_if_needed=false)
        return nil if not entity
        attrib_holder = Parametric.attribute_holder(entity)
        attribs =  attrib_holder ? attrib_holder.attribute_dictionary("skpp", create_if_needed) : nil
                  
        return nil if not attribs
        data = {}
        attribs.each { |key, value| data[key] = value}
        data
    end 


    def launchWebDialog
        return if @dialog_open
        
        # Make a directory called html in the same directory as this file, 
        # and write our HTML there.
        htmlDir = File.join( File.dirname(__FILE__), "html")
        Dir.mkdir( htmlDir) if not File.exist? htmlDir
        
        htmlFilename = File.join( htmlDir, "#{self.class}_#{@dict.unique_ID}.html")
        htmlWriter = LiveParametricHTMLWriter.new( @dict, htmlFilename)
            
        #Create the web dialog
        scrollable = true
        resizable = false

        html_width = htmlWriter.width
        html_height = htmlWriter.height
        # puts "launchWebDialog: dict = #{@dict} title:#{@dict.title} w:#{html_width} h:#{html_height}"
        dialog = UI::WebDialog.new(@dict.title, scrollable, "nil", html_width, html_height, 850, 150, resizable);

        # Process variable changes from the WebDialog
        dialog.add_action_callback("did_change") {|d,p| 
            key,val = p.split(",") if p
            # puts "LiveParametric.did_change:  #{key}: #{val}"
            
            # Only redraw if we have valid data
            if key and val
                # Find the dictionary that describes the changed variable
                changedVarDict = @dict.variableDicts.find{|d| d.unique_id == key}
                
                # Change its variable
                changedVarDict.setVal( val)
            
                # reload from the changed values
                LiveParametric.editFromDict( @dict)
            end
        }
    
        # Remove the html file when the dialog closes so we don't clutter everything up. 
        dialog.set_on_close{
            @dialog_open = false
            @dict.update( "dialog_open", @dialog_open)
            begin
                set_attributes(@dict.to_h)
            rescue TypeError
                # entities have already been deleted.  Don't do anything 
            end
            htmlWriter.delete_file
        }
    
        @dialog_open = true
        @dict.update( "dialog_open", @dialog_open)
        set_attributes( @dict.to_h)
        
        dialog.set_file(htmlWriter.filename, nil)
        # dialog.set_html(htmlWriter.html)
        dialog.show

    end

    # Parametric asks the user for input,  resulting in a 'data' object.
    # Supply it here
    def prompt( operation)
        if not @dict
            @dict = self.default_dict unless @dict
            launchWebDialog
        end
        LiveParametric.dataFromDict( @dict) 
    end

    def default_dict
        # ParameterDict args: ( title, parametricClassName, *variableDicts)
        p = ParameterDict.new(  self.controller_title,
                            self.class.to_s,
                            self.default_variables
                            )
        @@current_instances[p.unique_ID] = self

        p
    end
  
    def LiveParametric.dataFromDict( dict)
        data = dict.to_h
    end
    
    def setDict(dict)
        @dict = dict
    end
    
    def LiveParametric.editFromDict(dict)
        if not dict
            puts "LiveParametric.editFromDict  called with nil. returning"
            return nil
        end
        # puts "LiveParametric.editFromDict: d = #{dict}"
        data = LiveParametric.dataFromDict(dict)
        return unless data

        # create a new window if there's no window that's active
        Sketchup.file_new unless Sketchup.active_model

        ent_ID = data["unique_ID"]
        # If the LiveParametric object is already inside a group, this won't work...
        entity = Sketchup.active_model.active_entities.find{|e| e.get_attribute("skpp", "unique_ID") == ent_ID}

        klass = data["class_name"]
        new_method = eval "#{klass}.method :new"
        
        if entity
            # if there's already an entity, edit will replace it with the new version
            obj = new_method.call entity
            obj.setDict( dict)
            obj.edit
        else
            # otherwise, just create a new object
            obj = new_method.call data
        end
        nil
    end

    ########################################
    # Methods required of all LiveParametric subclasses
    ########################################
    def create_entities( data, container)
        puts <<-EOS
        #{self.class}: create_entities(data, container) method must be overridden by all subclasses
        # Valid implementations parse data and create shapes which are added to container:
        # ex:
        #
        # radius = data[@@radiusStr]
        # numSides = data[@@numSidesStr]
        #
        #  center = Geom::Point3d.new( 0,0,0)
        #  normal = Geom::Vector3d.new( 0,0,1)
        #
        #  circle = container.add_circle (center, normal, radius, numSides)
        EOS
    end

    def default_variables
        puts <<-EOS
        #{self.class}: default_variables() method must be overridden by all subclasses
        # A valid return value is an array of instances of VariableDict subclasses:
        # ex:
        # [# Slider args:  sliderLabel, minVal, maxVal, curVal, integer_only?
        #   Slider.new( @@radiusStr,   1,  10, 2),
        #   Slider.new( @@numSidesStr, 3, 100, 6, true)
        # ]
        EOS
    end

    ########################################
    # Methods optional for all LiveParametric subclasses
    # See also optional methods in parametric.rb for key translation, data validation, etc.
    ########################################
    def controller_title
        # Override with a more descriptive title in subclass if desired
        self.class.to_s
    end

end 

 

  

