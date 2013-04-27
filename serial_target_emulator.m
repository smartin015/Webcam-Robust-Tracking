classdef serial_target_emulator < serial_view_emulator
    properties
       object_vel;
       object_shown;
       circ_pos; 
       inserter;
    end
    
    methods
        function o = serial_target_emulator(pan)
           o = o@serial_debug(pan);
           o.object_vel = [0 0];
           o.object_shown = true;
           o.circ_pos = uint16([150 150 32]);
        end
        
        
    end
end