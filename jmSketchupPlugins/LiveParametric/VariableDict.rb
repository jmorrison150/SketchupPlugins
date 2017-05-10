
class VariableDict
    attr_reader :className, :varTitle, :html_width, :html_height
	attr_accessor :unique_id

    def initialize( varTitle)
        @varTitle = varTitle
        @className = self.class.to_s

		@html_width = 200
		@html_height = 90
    end

    def title
        @varTitle
    end

	######################################################################
	#  Mandatory override for all subclasses of VariableDict			 #
	######################################################################
    def to_html
        puts "#{self.class}: All subclasses of VariableDict must override to_html()"
    end

	######################################################################
	#  Optional overrides for all subclasses of VariableDict		 	 #
	######################################################################
	def setVal( val)
		# Subclasses may wish to set values with this with more complexity
		@curVal = val
	end

  def val
		# Override if you want more complex behavior
		@curVal
    end

	def headerCode
		# Override this with any specific files that need to be loaded: javascript libraries,
		# css, etc.
		[]
	end

end
