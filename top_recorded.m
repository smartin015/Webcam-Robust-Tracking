vidObj = VideoReader('test.avi');
nFrames = vidObj.NumberOfFrames;

% Read one frame at a time.
for k = 1 : nFrames
    IM = rgb2gray(read(vidObj, k));
    disp(k)
    bg_track(IM);
end