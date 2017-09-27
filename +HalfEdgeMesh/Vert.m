classdef Vert < handle

    properties
        halfs
        oppos
        inhfs
        index
    end
    
    methods
        function obj = Vert(v_index)
            if nargin > 0
                obj.index = v_index;
            end
        end
    end
    
end
