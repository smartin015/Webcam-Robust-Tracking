classdef turret < handle
    properties 
       ser;
       tracker;
       state;
       firing;
       vel;
    end 
    
    properties (Constant)
        STNAMES = {'CALIBRATE', 'BRAKE', 'LOCALIZE', 'FOLLOW', 'ATTACK'};
        ST_CALIBRATE = 1; % Rotate to create image panorama
        ST_BRAKE     = 2; % Stop all actions
        ST_LOCALIZE  = 3; % Search for position, but don't track objects
        ST_FOLLOW    = 4; % Search and track, but don't attack targets
        ST_ATTACK    = 5; % Search, track and neutralize!
        
        MAXROT  = 2*pi;
        WRAP_THRESH = 15;
        CALIBRATE_STARTUP_PD = 1000; %ms
        CALIBRATE_SPD = pi / 4; %Revolution takes 8 seconds.
    end
    
    methods
        function o = turret(serial_obj)
            %serial_obj is serial port object. must support write() func.
            %See serial_debug.m for a debug (printf) serial object.
            o.ser = serial_obj;
            
            %Start safe
            o.set_state(o.ST_BRAKE);
            o.set_speed(0);
            o.set_firing(0);
            o.ser_update(o.vel, o.firing); 
        end
        
        function ser_update(o, trigger_state, rotation_speed)
           % - trigger_state 1 or 0 => fire/stop firing
           % - rotation_speed => sets rotation speed in rad/sec
           
           %Sanitize
           trigger_state = uint8(trigger_state == 1); 
           rotation_speed = min(rotation_speed, o.MAXROT);
           rotation_speed = max(rotation_speed, -o.MAXROT);
           
           %TODO: Convert rot speed using feedback from camera
           rotation_bits = uint8(round(rotation_speed / o.MAXROT * intmax('int8')));
           rotation_bits = bitset(rotation_bits, 1, 0);
           
           %Now write in byte form to serial connection
           ser_byte = uint8(bitor(rotation_bits, trigger_state));
           o.ser.write(sprintf('%c', ser_byte));
        end
        
        function [oldtracker] = set_tracker(o, tracker)
            %Used for debug. Give it an already initialized tracker.
            oldtracker = o.tracker;
            o.tracker = tracker;
        end
        
        function set_state(o, MODE)
            o.state = MODE;
            fprintf('Changed state to %s\n', o.STNAMES{o.state});
        end
            
        function set_speed(o, spd)
            o.vel = spd;
        end
        
        function set_firing(o, firing)
            o.firing = firing;
        end
        
        function step(o, IM, delta_ms)
            % Calculates the next move given camera input
            switch (o.state)
                case o.ST_CALIBRATE
                    if (isempty(o.tracker))
                        o.tracker = bg_tracker(IM);
                    end
                    
                    o.firing = 0;
                    o.vel = o.CALIBRATE_SPD;
                    o.ser_update(o.firing, o.vel);
                    
                    %If we wrapped around, brake and wait for instructions
                    wrapped_around = o.tracker.calibrate(IM, o.vel * (delta_ms/1000));
                    if (wrapped_around)
                       o.tracker.crop();
                       o.set_state(o.ST_BRAKE);
                    end
                    
                    o.ser_update(0, o.CALIBRATE_SPD);
                    
                case o.ST_BRAKE 
                    %Stop everything ASAP. Bypass as much as possible.
                    o.ser.write(uint8(0));
                    o.firing = 0;
                    o.vel = 0;
                    return
                case o.ST_LOCALIZE
                    %Get position update estimate from tracker
                    %given current speed
                    rot_delta = o.tracker.estimate_shift(IM, o.vel * (delta_ms/1000));
                    
                    %TODO: PID loop for better tracking
                    
                    error('Implement localize');
                case o.ST_FOLLOW
                    error('Implement follow');
                case o.ST_ATTACK
                    error('Implement attack');
                otherwise
                    error('invalid state')
            end
        end
        
    end
end
