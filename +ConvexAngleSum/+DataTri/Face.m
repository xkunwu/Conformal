classdef Face < handle
    
    properties
%         normal
        num_entry
    end
    
    methods
        function obj = Face(num_entry)
            obj.num_entry = num_entry;
%             obj.normal = zeros(num_entry, 3);
        end
    end
    
end
