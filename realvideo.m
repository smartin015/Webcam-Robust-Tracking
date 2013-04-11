%Framework code stolen from http://www.matlabtips.com/realtime-processing/
%imaqhwinfo to get list

function realvideo()
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

    % This function is called by the timer to display one frame of the figure
end

function [result] = bg_track(frame) 
    persistent bg_panorama;
    persistent cam_pos;
    
    IMSZ = size(frame);
    if isempty(bg_panorama)
        % set up background panorama
        bg_panorama = uint8(zeros(IMSZ(1)*2, IMSZ(2)*2));
        bgsz = size(bg_panorama);
        fprintf('panorama init (%dx%d)\n', bgsz(2), bgsz(1));
        cam_pos = [IMSZ(1)/2 IMSZ(2)/2]; %Upper left corner of camera in bg_panorama 
    end
    
    %Calculate blurriness. If blurry, don't add to background
    
    
    %Attempt to match corner motion
    N_CORNERS = 10;
    C_new = corner(frame, N_CORNERS); %
    
    %Reject corners on the corners
    C_new =  mat2cell(C_new, ones(1,10), 2); %Pick 10 random corners
    THRESH = 5;
    C_new_reject = cellfun(@(p)(p(1) <= THRESH || p(2) <= THRESH || p(1) >= IMSZ(1)-THRESH || p(2) >= IMSZ(2)-THRESH), C_new); 
    C_new = C_new(not(C_new_reject));
    
    if (isempty(C_new))
        disp('No corners found');
        return;
    end
    
    new_chunks = cellfun(@(p)({frame(p(1)-THRESH:p(1)+THRESH, p(2)-THRESH:p(2)+THRESH)}),C_new);
    bg_chunks = cellfun(@(p)({bg_panorama(p(1)-5:p(1)+5, p(2)-5:p(2)+5)}),C_new);
    
    disp(sum(sum(new_chunks{1} - bg_chunks{1})));
        
    bg_panorama(cam_pos(1):cam_pos(1)+IMSZ(1)-1, cam_pos(2):cam_pos(2)+IMSZ(2)-1) = frame;
    
    result = bg_panorama;
end

function FrameRateDisplay(obj, event,vid)
    %persistent I_t1; %Image time t+1
    persistent handlesRaw;
    %persistent shapeInserter;

    trigger(vid);
    IM = rgb2gray(getdata(vid,1,'uint8'));
    
    %I_t1 = im2double(IM) ./ 255.0;
    if isempty(handlesRaw)
       % if first execution, we create the figure objects
       %subplot(2,1,1);
       pan = bg_track(IM);
       handlesRaw = imshow(pan);
       
       %shapeInserter = vision.ShapeInserter('Shape','Lines','BorderColor','Custom', 'CustomBorderColor', 255);
       
       %Allow us to get a previous image before tracking begins
       %I_t = I_t1;
       return 
    end
    
    %lines = videooptflowlines(of, 20);
    %mu = mean(lines(:,3:4) - lines(:,1:2)); %Mean direction of movement
    %disp(mu);
    %lines = [lines(1:2) bsxfun(@minus, lines(3:4), mu)];
    %if ~isempty(lines)
    %  IM =  step(shapeInserter, IM, lines); 
    %end
    pan = bg_track(IM);
    set(handlesRaw,'CData',pan);   
    
end


