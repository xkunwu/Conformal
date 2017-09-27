classdef Edge < handle

    properties
        halfs
        index
        
%         norm_2
%         cotw % cotan weight (half)
    end
    
    methods
        function obj = Edge(e_index)
            if nargin > 0
                obj.index = e_index;
            else
                obj.index = 0;
            end
        end
    end
    
end
