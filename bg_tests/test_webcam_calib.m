function test_webcam()
    IMSZ = [240 320]; %[H W]

    % Set-up webcam video input
    try
       vid = videoinput('winvideo', 2, sprintf('YUY2_%dx%d', IMSZ(2), IMSZ(1)));
    catch
       errordlg('No webcam or invalid image format');
       return
    end
    
    c = [onCleanup(@() stop(vid)) onCleanup(@() delete(vid))];
    setup(vid);
end

function setup(vid)
    global keymap keyval;
    addpath ../
    inserter = vision.ShapeInserter('Shape','Circles','Fill', true, 'Opacity', 1.0);
    object_vel = [0 0];
    object_shown = true;
    circ_pos = uint16([150 150 32]);
    keymap = {'uparrow', 'downarrow', 'leftarrow', 'rightarrow'};
    keyval = zeros(1,4);
    
    hFigure = figure(1);
    camIM = imshow(zeros(240,320), [0 255]);
    
    %Init serial
    if (not(isempty(instrfind)))
        fclose(instrfind);
    end
    ser = serial('COM11');
    fopen(ser);
    ser_obj = serial_com(ser);
    
    %Turret object. Initialize with tracker and start fixed detect mode
    t = turret(ser_obj);
    t.set_state(turret.ST_CALIBRATE);
    
    % Set parameters for video
    % Acquire only one frame each time
    set(vid,'FramesPerTrigger',1);
    % Go on forever until stopped
    set(vid,'TriggerRepeat',Inf);
    % Get a grayscale image
    set(vid,'ReturnedColorSpace','RGB');
    triggerconfig(vid, 'Manual');
    
    % set up and start timer
    NumberFrameDisplayPerSecond = 3;
    dt = 1000/NumberFrameDisplayPerSecond;
    TimerData=timer('TimerFcn', {@FrameRateDisplay,vid},'Period',1/NumberFrameDisplayPerSecond,'ExecutionMode','fixedRate','BusyMode','drop');
    
    start(vid);
    start(TimerData);
    
    function FrameRateDisplay(obj, event, vid)
        trigger(vid);
        IM = rgb2gray(getdata(vid,1,'uint8'));
        set(camIM, 'CData', IM);
        t.step(IM, dt);
    end

    % We go on until the figure is closed
    uiwait(hFigure);

    % Clean up everything
    stop(TimerData);
    delete(TimerData);
    fclose(ser);
    rmpath ../
end