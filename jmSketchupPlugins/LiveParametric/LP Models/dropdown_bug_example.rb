#!/usr/bin/env ruby -wKU

class DropdownBugExample < LiveParametric
    # Correct behavior would yield a dropdown list with these entries:
    #    good element
    #    missing <bracketed> word
    #
    # Actual behavior yields:
    #    good element
    #    missing word
    @@ddTitle = "test_dropdown"
    def default_variables
        possible_vals = ["good element", "missing <bracketed> word"]
        [ DropdownList.new(@@ddTitle, possible_vals, "good element")]
    end
    def create_entities( data, container)
        # dropdown output is in data[@ddTitle]
        # data.each{|k,v| puts "#{k}: >#{v}<"}
        
        container.add_face( [[0,0,0],[0,1,0],[1,0,0]])
    end
end