classdef Half < handle

    properties
        oppo
        prev
        next
        source
        target
        face
        edge
        index
        
    end
    
    methods
        function obj = Half(h_index)
            if nargin > 0
                obj.index = h_index;
            else
                obj.index = 0;
            end
            obj.face = [];
            obj.edge = [];
        end
    end
    
end
