require 'VariableDict.rb'

class Button < VariableDict
    def initialize( varTitle, methodStr)
        super( varTitle)
        @methodStr = methodStr
    end

    def val
        nil
    end
end
