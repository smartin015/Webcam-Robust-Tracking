%Most legit test sequence. 
%Panoramic image with injected noise, wraps around
%Then commences blind orientation tests
%(With and without foreground objects)

clear functions
clear tracker
addpath ../

pan = rgb2gray(imread('sonycenter.png'));
pan_wide = size(pan,2);
pan = [pan pan(:,1:400)]; %Wrap it a wee bit
hpos = 1;
WIDTH = 320;
HEIGHT = 240;

% Read one frame at a time.
first = pan(:, hpos:hpos+WIDTH-1);
tracker = bg_tracker(first);

% --------- Build up background image from consecutive samples ---------
THRESH = 15;
wrapped = -1;
for k = 1 : size(pan,2)
    IM = pan(:, hpos:hpos+WIDTH-1);
    
    %Add image noise
    IM = imnoise(IM, 'gaussian');
    
    tracker.calibrate(IM, 0);
    pause(0.01);
    
    %Random jump forward
    hpos = hpos + randi(5); 
    
    %Wrap around
    if (hpos > pan_wide)
        hpos = hpos - pan_wide;
    end

    if (k > 100 && mean(mean(first - IM)) < THRESH && wrapped < 0) %Check for wraparound
       fprintf('Wraparound! mean px deviation %0.2f \n', mean(mean(first-IM)));
       wrapped = 10;
    end
    
    if (wrapped == 0)
        break;
    end
    
    wrapped = wrapped - 1;
end

%Set the background
tracker.crop();

% -------- Test prediction accuracy --------
NOISE = true;
FGOBJS= false;
BLUR  = false;

if (FGOBJS)
    inserter = vision.ShapeInserter('Fill', true, 'Opacity', 1.0);
    rectWidths = [30 40; 10 10; 18 27; 10 5];
    MAX_OBJECTS = 5;
end

if (BLUR)
    MAX_MOTION_LEN = 8;   
end

fprintf('Testing obscured prediction accuracy... \n');
NTESTS = 200;
test_points = randsample(pan_wide, NTESTS);
num_correct = 0;

for i=1:NTESTS
   hpos = test_points(i);
   IM = pan(:, hpos:hpos+WIDTH-1);
   
   if (FGOBJS)
       %Add a few objects
       nobjs = randi(MAX_OBJECTS);
       rectangles = uint16(zeros(nobjs, 4));
       for j=1:nobjs
        pos = [randi([50, HEIGHT-50]), randi([50, WIDTH-50])];
        rectangles(j,:) = [pos rectWidths(randi(length(rectWidths)), :)];
       end
       IM = step(inserter, IM, rectangles);
   end
   
   if (BLUR)
       %Add ze motion blur
       len = randi(MAX_MOTION_LEN);
       theta = 180*(randi(2)-1); %either left or right
       motionFilter = fspecial('motion', len, theta);
       IM = imfilter(IM,motionFilter,'replicate');
   end
   
   if (NOISE)
       IM = imnoise(IM, 'gaussian');
   end
   
   %add a random number of objects 
   [test, c] = tracker.search(IM);
   
   if (abs(test - hpos) <= 1)
        num_correct = num_correct + 1;
   else
       fprintf('Failed on test %d vs actual %d\n', test, hpos);
   end
end

figure();
imshow(IM);
title('Example Test Image');
fprintf('Obscured prediction accuracy: %0.2f%% \n', num_correct / NTESTS * 100);

%TODO: Test prediction with deemphasized foreground objects
% ## Requires implementation of foreground object removal ##

rmpath ../
clear functions
