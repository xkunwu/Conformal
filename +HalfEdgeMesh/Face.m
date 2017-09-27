classdef Face < handle

    properties
        halfs
        index
        
%         normal
    end
    
    methods
        function obj = Face(f_index)
            if nargin > 0
                obj.index = f_index;
            end
        end
    end
    
end
