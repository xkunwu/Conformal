classdef Half < handle

    properties
        alpha % angle opposite to this half edge
        cota % cot(alpha)
        length
        num_entry
    end
    
    methods
        function obj = Half(num_entry)
            obj.num_entry = num_entry;
            obj.alpha = zeros(num_entry, 1);
            obj.cota = zeros(num_entry, 1);
        end
    end
    
end
