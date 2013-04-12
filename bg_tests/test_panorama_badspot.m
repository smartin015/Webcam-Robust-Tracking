%Test using test.avi video

clear functions
addpath ../

pan = rgb2gray(imread('sonycenter.png'));
pan_wide = size(pan,2);
pan = [pan pan(:,1:600)]; %Wrap it a wee bit
hpos = 720;
WIDTH = 320;

% Read one frame at a time.
first = pan(:, hpos:hpos+WIDTH);


p1 = 15;
IM = pan(:, hpos+p1:hpos+p1+WIDTH);
IM2 = pan(:, hpos+p1+3:hpos+p1+3+WIDTH);
bg_track_lines(IM);
bg_track_lines(IM, 'train');
bg_track_lines(IM2, 'train');

%{
%Build up background image from consecutive samples
for k = 1 : 50
    IM = pan(:, hpos:hpos+WIDTH);
    bg_track_lines(IM);
    hpos = hpos + randi(3); %TODO: Make random
    pause(0.05);
end
%}

rmpath ../
clear functions
