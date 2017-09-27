classdef Edge < handle
    
    properties
        length
        lambda
        cotw % cotan weight (one half of the sum)
        num_entry
    end
    
    methods
        function obj = Edge(num_entry)
            obj.num_entry = num_entry;
            obj.length = zeros(num_entry, 1);
            obj.cotw = zeros(num_entry, 1);
        end
    end
    
end
