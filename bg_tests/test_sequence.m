
clear functions
addpath ../

ball = './ball/';
downtown = './downtown/';
%Add folders as necessary

path = downtown;
nFrames = 3;

ims = cell(1, nFrames);
for i=1:nFrames
    path_i = sprintf('%s%d.png', path, i);
    fprintf('Loading %s\n', path_i);
    ims{i} = imread(path_i);
end

bg_track_lines(rgb2gray(ims{1}), 'train');
% Read one frame at a time.
for k = 1 : length(ims)
    IM = rgb2gray(ims{k});
    bg_track_lines(IM, 'train');
    pause(0.1);
end

rmpath ../
clear functions
