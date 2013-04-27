classdef serial_template < handle   
    methods
        function o = serial_template()
        end
        
        function [vel, firing] = decode(~,c)
            c = int8(c);
            firing = bitand(c,1);
            vel = double(bitset(c, 1, 0));
        end
        
        function write(~, c)
            [vel, firing] = decode(c);
            if (firing)
                firestr = 'firing';
            else
                firestr = '';
            end
            fprintf('%d %s\n', vel, firestr);
        end
    end
end