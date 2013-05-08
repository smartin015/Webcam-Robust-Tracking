%Framework code stolen from http://www.matlabtips.com/realtime-processing/
%imaqhwinfo to get list

function realvideo()
    IMSZ = [240 320]; %[H W]

    % Set-up webcam video input
    try
       vid = videoinput('winvideo', 1, sprintf('YUY2_%dx%d', IMSZ(2), IMSZ(1)));
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

    % set up timer object
    TimerData=timer('TimerFcn', {@FrameRateDisplay,vid},'Period',1/NumberFrameDisplayPerSecond,'ExecutionMode','fixedRate','BusyMode','drop');
    
    % Start video and timer object
    start(vid);
    start(TimerData);

    % We go on until the figure is closed
    uiwait(hFigure);

    % Clean up everything
    stop(TimerData);
    delete(TimerData);
    
    % clear persistent variables
    clear functions;
end

function FrameRateDisplay(obj, event,vid)
    persistent handlesRaw;
    
    trigger(vid);
    IM = rgb2gray(getdata(vid,1,'uint8'));
    if isempty(handlesRaw)
        handlesRaw = imshow(IM);
    else
        set(handlesRaw, 'CData', IM);
    end
    
end


