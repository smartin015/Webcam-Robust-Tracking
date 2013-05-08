%Simple test of the background tracker in handling 
%rotation of the camera. We move the camera at high
%speed and check to ensure the estimated background 
%position keeps up with it.
% TODO: Switch to feature-based tracking over xcorr
%Scott Martin <semartin@andrew.cmu.edu>

addpath ../
close all
clear all

%Target & Camera emulator
pan = rgb2gray(imread('sonycenter.png'));
temu = serial_target_emulator(pan);
IM = temu.next_frame(0);

%Background tracker (precalibrated)
tracker = bg_tracker(IM);
tracker.loadexisting('tracker.mat');
tracker.h_pos = tracker.search(IM);

keyval = [0 0 1 0]; %Go left!
dt = 1000/20;
subplot(2,1,1);
nowhandle = imshow(IM);
subplot(2,1,2);
bghandle = imshow(tracker.get_frame());
for i=1:100
    temu.update_target(keyval, 0);
    temu.write(-128); %Hard left
    IM = temu.next_frame(dt); %ms/frame
    %[dist, rot] = tracker.estimate_shift(IM, 0);
    hpos = tracker.search(IM);
    fprintf('%d px moved\n', tracker.h_pos - hpos);
    tracker.h_pos = hpos;
    pause(0.2);
    set(nowhandle, 'CData', IM);
    set(bghandle, 'CData', tracker.get_frame());
end

rmpath ../