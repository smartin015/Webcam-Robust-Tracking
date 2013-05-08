% A simpler test of test_turret_tracking,
% allows for easier code profiling to detect bottlenecks.
% Just go in one direction and test accuracy of tracking.
% Scott Martin <semartin@andrew.cmu.edu>
% 5/2013

addpath ../
close all
clear all
inserter = vision.ShapeInserter('Shape','Circles','Fill', true, 'Opacity', 1.0);
object_vel = [0 0];
circ_pos = uint16([150 150 32]);

%Target & Camera emulator
pan = rgb2gray(imread('sonycenter.png'));
temu = serial_target_emulator(pan);
IM = temu.next_frame(0);

%Background tracker (precalibrated)
tracker = bg_tracker(IM);
tracker.loadexisting('tracker.mat');
tracker.h_pos = tracker.search(IM);

%Turret object. Initialize with tracker and start fixed detect mode
t = turret(temu);
t.set_tracker(tracker);
t.set_state(turret.ST_FOLLOW);



keyval = [0 0 1 0]; %Go left!
dt = 1000/20;
for i=1:100
    temu.update_target(keyval, 1);
    IM = temu.next_frame(dt); %ms/frame
    t.step(IM, dt);
    pause(0.001);
end

rmpath ../