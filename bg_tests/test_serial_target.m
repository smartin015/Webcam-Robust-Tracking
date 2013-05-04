function test_keyboard_input()
    global keymap keyval;
    inserter = vision.ShapeInserter('Shape','Circles','Fill', true, 'Opacity', 1.0);
    object_vel = [0 0];
    object_shown = true;
    circ_pos = uint16([150 150 32]);
    keymap = {'uparrow', 'downarrow', 'leftarrow', 'rightarrow'};
    keyval = zeros(1,4);
    
    pan = rgb2gray(imread('sonycenter.png'));
    temu = serial_target_emulator(pan);
    
    Screen.fh = figure('KeyPressFcn', @KeyPress, 'KeyReleaseFcn', @KeyRelease);
    f = imshow(temu.next_frame(0), 'Border', 'tight');
    
    % set up and start timer
    NumberFrameDisplayPerSecond = 22;
    TimerData=timer('TimerFcn', {@FrameRateDisplay},'Period',1/NumberFrameDisplayPerSecond,'ExecutionMode','fixedRate','BusyMode','drop');
    start(TimerData);

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
    
    function FrameRateDisplay(obj, event)
        temu.write(int8(126));
        temu.update_target(keyval, object_shown);
        IM = temu.next_frame(1000/NumberFrameDisplayPerSecond);
        set(f, 'CData', IM);
    end

    % We go on until the figure is closed
    uiwait(Screen.fh);

    % Clean up everything
    stop(TimerData);
    delete(TimerData);
    
end




