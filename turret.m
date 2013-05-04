classdef turret < handle
    properties 
       ser;
       tracker;
       state;
       firing;
       vel;
       fghandle;
       camhandle;
       bghandle;
       crosshairsInserter;
       crosshairs;
       props;
       pid_int;
       pid_prev;
    end 
    
    properties (Constant)
        STNAMES = {'CALIBRATE', 'BRAKE', 'FIXED', 'FOLLOW', 'ATTACK'};
        ST_CALIBRATE = 1; % Rotate to create image panorama
        ST_BRAKE     = 2; % Stop all actions
        ST_FIXED     = 3; % Search for objects, but don't track them
        ST_FOLLOW    = 4; % Search and track, but don't attack targets
        ST_ATTACK    = 5; % Search, track and neutralize!
        
        IMWIDTH = 320; %TODO: Considering moving to init
        MAXROT  = 2*pi;
        WRAP_THRESH = 15;
        CALIBRATE_STARTUP_PD = 1000; %ms
        CALIBRATE_SPD = pi / 4; %Revolution takes 8 seconds.
        PID = [1 1 1]; %Coefficients for PID control
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
            
            figure('Name', 'Views');
            subplot(1,3,1);
            o.fghandle = imshow(zeros(240,320), [0 1]);
            subplot(1,3,2)
            o.bghandle = imshow(zeros(240,320), [0 255]);
            subplot(1,3,3);
            o.camhandle = imshow(zeros(240,320,3), [0 255]);
            
            o.crosshairsInserter = vision.ShapeInserter('BorderColor','Custom','CustomBorderColor',uint8([0 255 0]));
            o.crosshairs = int32([10 10 30 30]);
            
            %Init PID
            o.pid_int = 0;
            o.pid_prev = 0;
        end
        
        function ser_update(o, trigger_state, rotation_speed)
           % - trigger_state 1 or 0 => fire/stop firing
           % - rotation_speed => sets rotation speed in rad/sec
           
           %Sanitize
           trigger_state = int8(trigger_state == 1); 
           rotation_speed = min(rotation_speed, o.MAXROT);
           rotation_speed = max(rotation_speed, -o.MAXROT);
           
           %TODO: Convert rot speed using feedback from camera
           rotation_bits = int8(round(rotation_speed / o.MAXROT * intmax('int8')));
           rotation_bits = bitset(rotation_bits, 1, 0);
           
           
           %Now write in byte form to serial connection
           ser_byte = int8(bitor(rotation_bits, trigger_state));
           o.ser.write(ser_byte);
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
                    
                    set(o.camhandle, 'CData', IM);
                    
                case o.ST_BRAKE 
                    %Stop everything ASAP. Bypass as much as possible.
                    o.ser.write(uint8(0));
                    o.firing = 0;
                    o.vel = 0;
                    set(o.camhandle, 'CData', IM);
                    return
                case o.ST_FIXED
                    %Get position update estimate from tracker
                    %given current speed
                    rot_delta = o.tracker.estimate_shift(IM, o.vel * (delta_ms/1000));
                    
                    %Subtract the background to detect foreground objects
                    im2 = o.tracker.get_frame();
                    [fg_mask, fg_props] = detect_objects(IM, im2);
                    fprintf('%d blobs found\n', length(fg_props));
                    set(o.fghandle, 'CData', fg_mask);
                    o.props = fg_props;
                    IMcol = repmat(IM,[1,1,3]);
                    if ~isempty(fg_props)
                        for i=1:length(fg_props)
                            o.crosshairs = uint16(fg_props(1).BoundingBox);
                            IMcol = step(o.crosshairsInserter, IMcol, o.crosshairs);
                            %TODO: vision.TextInserter
                        end
                    end
                    set(o.camhandle, 'CData', IMcol);
                case o.ST_FOLLOW
                    %Get position update estimate from tracker
                    %given current speed
                    rot_delta = o.tracker.estimate_shift(IM, o.vel * (delta_ms/1000));
                    
                    %Subtract the background to detect foreground objects
                    im2 = o.tracker.get_frame();
                    set(o.bghandle, 'CData', im2);
                    
                    [fg_mask, fg_props] = detect_objects(IM, im2);
                    fprintf('%d blobs found\n', length(fg_props));
                    set(o.fghandle, 'CData', fg_mask);
                    o.props = fg_props;
                    IMcol = repmat(IM,[1,1,3]);
                    if ~isempty(fg_props)
                        o.crosshairs = uint16(fg_props(1).BoundingBox);
                        IMcol = step(o.crosshairsInserter, IMcol, o.crosshairs);
                        
                        %TODO: vision.TextInserter
                        
                        %TODO: Prioritize based on movement amount. If it
                        %doesn't move relative to background, consider
                        %not shooting it. 
                        
                        error = fg_props(1).Centroid(1) - o.IMWIDTH/2;
                        o.pid_int = 0.75*o.pid_int + error; %Geometric weighted integral... 0.3% influence by step 20.
                        pid_d = error - o.pid_prev;
                        action = o.PID(1) * error + o.PID(2) * o.pid_int + o.PID(3) * pid_d;
                        o.pid_prev = error;
                        o.ser_update(0, action);
                    end
                    set(o.camhandle, 'CData', IMcol);
                case o.ST_ATTACK
                    error('Implement attack');
                otherwise
                    error('invalid state')
            end
        end
        
    end
end
