% Set-up webcam video input

function record()
    try
       vid = videoinput('winvideo', 2, 'YUY2_320x240');
    catch
       errordlg('No webcam or invalid image format');
       return
    end

    c = [onCleanup(@() stop(vid)) onCleanup(@() delete(vid))];
    setup(vid);
end


function setup(vid)
    % Define frame rate
    NumberFrameDisplayPerSecond=20;

    % Open figure
    hFigure=figure(1);

    % Set parameters for video
    % Acquire only one frame each time
    set(vid,'FramesPerTrigger',1);
    % Go on forever until stopped
    set(vid,'TriggerRepeat',Inf);
    % Get a grayscale image
    set(vid,'ReturnedColorSpace','RGB');
    triggerconfig(vid, 'Manual');

    % Create a new AVI file
    writerObj = VideoWriter('test.avi');
    open(writerObj);
    
    % set up timer object
    TimerData=timer('TimerFcn', {@FrameRateDisplay,vid, writerObj},'Period',1/NumberFrameDisplayPerSecond,'ExecutionMode','fixedRate','BusyMode','drop');
    
    % Start video and timer object
    start(vid);
    start(TimerData);

    % We go on until the figure is closed
    uiwait(hFigure);

    % Close the AVI file
    close(writerObj);         
    
    % Clean up everything
    stop(TimerData);
    delete(TimerData);
    delete(writerObj);
    
    % clear persistent variables
    clear functions;
end

function FrameRateDisplay(obj, event, vid, writerObj)
    persistent handlesRaw;
    trigger(vid);
    IM = rgb2gray(getdata(vid,1,'uint8'));
    if (isempty(handlesRaw))
       handlesRaw = imshow(IM); 
    end
    writeVideo(writerObj,IM);
    set(handlesRaw,'CData',IM);  
end