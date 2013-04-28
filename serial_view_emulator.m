classdef serial_view_emulator < serial_template
    properties
        firing;
        vel;
        target_vel;
        pan;
        hpos;
        pan_wide;
    end
    
    properties (Constant)
       WIDTH = 320;
       HEIGHT = 240;
       MAX_ROT = 2*pi; %rad/sec
       VEL_TO_ANG = 2*pi / (intmax('int8') - 1); 
       MOMENTUM = 0.9; %Proportion of old velocity influence
    end
    
    methods
        function o = serial_view_emulator(pan)
            o = o@serial_template();
            o.pan_wide = size(pan,2);
            o.pan = [pan pan(:,1:400)]; %Wrap it a wee bit
            o.hpos = 20;
            o.vel = 0;
            o.target_vel = 0;
        end
        
        function write(o, c)
            c = int8(c);
            [o.target_vel, o.firing] = o.decode(c);
        end
        
        function [IM] = apply_noise(~, IM, px_movement)
            %Add motion blur if we're moving
            len = floor(abs(px_movement));
            if (len > 0)
                theta = 0;
                if (px_movement < 0)
                    theta = 180;
                end
                motionFilter = fspecial('motion', len, theta);
                IM = imfilter(IM,motionFilter,'replicate');
            end
            
            %Add some image noise
            IM = imnoise(IM, 'gaussian');
        end
        
        function [px_movement] = update_pos(o, delta_ms)
            %Accelerate towards desired velocity
            o.vel = o.MOMENTUM * o.vel + (1 - o.MOMENTUM) * o.target_vel;
            dt = delta_ms / 1000.0;
            px_movement = 2*(o.vel .* dt);
            o.hpos = o.hpos + px_movement;
            
            %Allow wraparound
            if (o.hpos < 10)
                o.hpos = o.hpos + o.pan_wide;
            elseif (o.hpos > o.pan_wide + 10)
                o.hpos = o.hpos - o.pan_wide;
            end
        end
        
        function [IM] = get_current_view(o)
            IM = o.pan(:, round(o.hpos):round(o.hpos)+o.WIDTH-1);
        end
        
        function IM = next_frame(o, delta_ms)
            %Updates position and returns a snapshot of what the camera
            %would see at the current position. Includes gaussian noise and
            %motion blur. 
            
            px_movement = o.update_pos(delta_ms);
            IM = o.apply_noise(o.get_current_view(), px_movement);
        end
    end
end