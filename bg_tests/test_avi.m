%Test using test.avi video

clear functions
addpath ../

vidObj = VideoReader('test.avi');
nFrames = vidObj.NumberOfFrames;

% Read one frame at a time.
for k = 1 : nFrames
    IM = rgb2gray(read(vidObj, k));
    bg_track_lines(IM);
    pause(0.1);
end

rmpath ../
clear functions
