%Most legit test sequence. 
%Panoramic image with injected noise, wraps around
%Then commences blind orientation tests
%(With and without foreground objects)

clear functions
addpath ../

pan = rgb2gray(imread('sonycenter.png'));
pan_wide = size(pan,2);
pan = [pan pan(:,1:400)]; %Wrap it a wee bit
hpos = 1;
WIDTH = 320;

% Read one frame at a time.
first = pan(:, hpos:hpos+WIDTH);
tracker = bg_tracker(first);

%Build up background image from consecutive samples
THRESH = 15;
wrapped = -1;
for k = 1 : size(pan,2)
    IM = pan(:, hpos:hpos+WIDTH);
    
    %Add image noise
    IM = imnoise(IM, 'gaussian');
    
    tracker.track(IM);
    pause(0.01);
    
    %Random jump forward
    hpos = hpos + randi(5); 
    
    %Wrap around
    if (hpos > pan_wide)
        hpos = hpos - pan_wide;
    end

    disp( mean(mean(first - IM)));
    if (k > 100 && mean(mean(first - IM)) < THRESH) %Check for wraparound
       disp('Wraparound!');
       wrapped = 10;
    end
    
    if (wrapped == 0)
        break;
    end
    
    wrapped = wrapped - 1;
end

%TODO: Test blind prediction accuracy
%test_points = randsample(

%TODO: Test prediction with foreground obfuscation


%TODO: Test prediction with deemphasized foreground objects

rmpath ../
clear functions
