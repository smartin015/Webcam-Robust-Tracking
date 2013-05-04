classdef serial_template < handle   
    methods
        function o = serial_template()
        end
        
        function [vel, firing] = decode(~,c)
            %Takes in uint8 (char) C value
            if (not(length(c) == 1))
                error(sprintf('Invalid byte %s given', c));
            end
            %disp(c);
            firing = bitand(int8(c), int8(1)); %Get bottom bit
            
            %Probably low enough jitter to not worry about an extra bit
            vel = double(c); 
            %vel = double(bitand(c, int8(hex2dec('FE')))); %Causes errors
        end
        
        function write(~, c)
            disp('Writing:');
            disp(c);
            
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