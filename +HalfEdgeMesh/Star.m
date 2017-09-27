classdef Star < handle

    properties
        halfs
        oppos
        index
    end
    
    methods
        function obj = Star(v_index)
            if nargin > 0
                obj.index = v_index;
            end
        end
    end
    
end
