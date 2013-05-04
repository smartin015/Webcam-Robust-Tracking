classdef serial_target_emulator < serial_view_emulator
    properties
       object_vel;
       object_shown;
       circ_pos; 
       inserter;
    end
    
    methods
        function o = serial_target_emulator(pan)
           o = o@serial_view_emulator(pan);
           o.object_vel = [0 0];
           o.object_shown = true;
           o.circ_pos = int16([150 150 32]);
           o.inserter = vision.ShapeInserter('Shape','Circles','Fill', true, 'Opacity', 1.0);
        end
        
        function update_target(o, keyval, shown)
            %Given array [left, right, up, down]
            %updates emulated object velocity
            o.object_shown = shown;
            direction = [(keyval(4) - keyval(3)) (keyval(2) - keyval(1))];
            o.object_vel = 0.85 * o.object_vel + direction;
            o.circ_pos(1) = o.circ_pos(1) + o.object_vel(1);
            o.circ_pos(2) = o.circ_pos(2) + o.object_vel(2);
            %Allow wraparound
            if (o.circ_pos(1) < 1)
                o.circ_pos(1) = o.circ_pos(1) + o.pan_wide;
            elseif (o.circ_pos(1) > o.pan_wide + 1)
                o.circ_pos(1) = o.circ_pos(1) - o.pan_wide;
            end
        end
        
        function IM = next_frame(o, delta_ms)
            %Updates position and returns a snapshot of what the camera
            %would see at the current position. Includes gaussian noise and
            %motion blur. 
            
            px_movement = o.update_pos(delta_ms);
            %fprintf('Moving %d px', px_movement);
            IM = o.get_current_view();
            pos_rel = int16([o.circ_pos(1) o.circ_pos(2) o.circ_pos(3)]);
            
            %Special cases for wraparound
            pos_candidates = [double(o.circ_pos(1)) - o.hpos ...
                              double(o.circ_pos(1)) - (o.hpos + o.pan_wide) ...
                              double(o.circ_pos(1)) - (o.hpos - o.pan_wide)];
            best_candidate = pos_candidates(abs(pos_candidates) == min(abs(pos_candidates)));
            pos_rel(1) = int16(best_candidate(1));
            
            if (o.object_shown)
                imspr = step(o.inserter, IM, pos_rel);
            else
                imspr = IM;
            end
            IM = o.apply_noise(imspr, px_movement);
        end
    end
end