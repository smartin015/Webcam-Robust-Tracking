function test_keyboard_input()
    global keymap keyval;
    inserter = vision.ShapeInserter('Shape','Circles','Fill', true, 'Opacity', 1.0);
    im = 255*ones(240,320);
    object_vel = [0 0];
    object_shown = true;
    circ_pos = uint16([150 150 32]);
    keymap = {'uparrow', 'downarrow', 'leftarrow', 'rightarrow'};
    keyval = zeros(1,4);
    
    Screen.fh = figure('KeyPressFcn', @KeyPress, 'KeyReleaseFcn', @KeyRelease);
    f = imshow(im, 'Border', 'tight');
    
    % set up and start timer
    NumberFrameDisplayPerSecond = 15;
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
        direction = [(keyval(4) - keyval(3)) (keyval(2) - keyval(1))];
        object_vel = 0.85 * object_vel + 2*direction;
        circ_pos(1) = circ_pos(1) + object_vel(1);
        circ_pos(2) = circ_pos(2) + object_vel(2);
        
        if (object_shown)
            imspr = step(inserter, im, circ_pos);
        else
            imspr = im;
        end
        set(f, 'CData', imspr);
    end

    % We go on until the figure is closed
    uiwait(Screen.fh);

    % Clean up everything
    stop(TimerData);
    delete(TimerData);
    
end




