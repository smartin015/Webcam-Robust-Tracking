% Transmits serial instructions to an arduino
% to control servo rotation speed and trigger action. 
% Note that this currently translates a magnitude-based
% directional command to simple left/right, as the 
% servo resolution was determined to be too low.
% TODO: Fix this in future version
% Scott Martin <semartin@andrew.cmu.edu>
% 5/2013

classdef serial_com < serial_template
    properties
        ser
    end
    properties (Constant)
       SERVO_MID = 94 
    end
    methods
        function o = serial_com(ser)
            o.ser = ser;
        end
        
        function write(o, c)
            %disp('Writing:');
            %disp(c);
            
            [vel, firing] = o.decode(c);
            if (firing)
                firestr = 'firing';
            else
                firestr = '';
            end
            
            %Translate into 'left, right, stop' command
            if (abs(vel) < 5)
                vel = o.SERVO_MID;
            elseif (vel > 0)
                vel = o.SERVO_MID + 2;
            else
                vel = o.SERVO_MID - 1;
            end
            
            fprintf(o.ser, sprintf('%d %s\n', vel, firestr), 'async');
        end
    end
end