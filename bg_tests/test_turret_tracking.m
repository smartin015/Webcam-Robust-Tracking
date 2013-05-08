

function test_turret_tracking()
    global keymap keyval;
    addpath ../
    inserter = vision.ShapeInserter('Shape','Circles','Fill', true, 'Opacity', 1.0);
    object_vel = [0 0];
    object_shown = true;
    circ_pos = uint16([150 150 32]);
    keymap = {'uparrow', 'downarrow', 'leftarrow', 'rightarrow'};
    keyval = zeros(1,4);
    
    %Target & Camera emulator
    pan = rgb2gray(imread('sonycenter.png'));
    temu = serial_target_emulator(pan);
    IM = temu.next_frame(0);
    
    %Background tracker (precalibrated)
    tracker = bg_tracker(IM);
    tracker.loadexisting('tracker.mat');
    tracker.h_pos = tracker.search(IM);
    
    %Turret object. Initialize with tracker and start fixed detect mode
    t = turret(temu);
    t.set_tracker(tracker);
    t.set_state(turret.ST_FOLLOW);
    
    Screen.fh = figure('KeyPressFcn', @KeyPress, 'KeyReleaseFcn', @KeyRelease);
    
    % set up and start timer
    NumberFrameDisplayPerSecond = 3;
    dt = 1000/NumberFrameDisplayPerSecond;
    %TimerData=timer('TimerFcn', {@FrameRateDisplay},'Period',1/NumberFrameDisplayPerSecond,'ExecutionMode','fixedRate','BusyMode','drop');
    %start(TimerData);

    function KeyPress(varargin) 
        one_a = varargin{2};
        [m,i] = ismember(one_a.Key, keymap);
        if (m)
            keyval(i) = 1;
        end
    end 

    function KeyRelease(varargin) 
        one_a = varargin{2};
        [m,i] = ismember(one_a.Key, keymap);
        if (m)
           keyval(i) = 0; 
        end
        
        if (strcmp(one_a.Key, 'space'))
            object_shown = not(object_shown);
        end
    end 
    
    %function FrameRateDisplay(obj, event)
    while (1)
        temu.update_target(keyval, object_shown);
        IM = temu.next_frame(1000/NumberFrameDisplayPerSecond);
        t.step(IM, dt);
        pause(0.1);
    end

    % We go on until the figure is closed
    uiwait(Screen.fh);

    % Clean up everything
    %stop(TimerData);
    %delete(TimerData);
    rmpath ../
end