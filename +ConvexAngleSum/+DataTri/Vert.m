classdef Vert < handle
    
    properties
        u % logarithm of length (metric) change
        angle_sum
        num_entry
    end
    
    methods
        function obj = Vert(num_entry)
            obj.num_entry = num_entry;
            obj.u = zeros(1, num_entry);
            obj.angle_sum = zeros(1, num_entry);
        end
    end
    
end
