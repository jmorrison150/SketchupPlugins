
class ParameterDict
    attr_reader :variableDicts, :outputPath, :title, :updateMethodStr, :unique_ID, :className

    def initialize( title, parametricClassName, variableDicts)
        @title = title
        @className = parametricClassName
        @updateMethodStr = updateMethodStr
        @outputPath = outputPath
        @unique_ID = self.object_id
        @variableDicts = variableDicts
		
		@state = { "unique_ID" => @unique_ID,
				   "class_name" => @className}
		
		# Set unique_ids for each variableDict
		@variableDicts.each_with_index {|e, i|  
			e.unique_id = "#{e.class}_#{i}"
		}

    end

	def update( key, val)
		# if the key and value describe one of the variables, change them
		if changedVarDict = variableDicts.find{|d| d.unique_id == key || d.varTitle == key}
			changedVarDict.setVal( val)
		else
			#Otherwise, they describe some other state that needs to be stored
			@state[key] = val
		end
	end
	
    def to_h
        data = {}
        @variableDicts.each{ |e| data[e.title] = e.val}
		@state.each_pair{|k,v| data[k] = v}
        data
    end

    def setVariableDicts( dictsArr)
        @variableDicts = dictsArr
    end

end