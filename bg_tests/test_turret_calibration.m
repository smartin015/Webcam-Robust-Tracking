
clear functions
clear turret
close all
addpath ../

NFRAMES_CALIB_MAX = 1000;
FPS = 22;
dt = 1000/FPS;

pan = rgb2gray(imread('sonycenter.png'));
serdbg = serial_view_emulator(pan);
IM = serdbg.next_frame(dt);
h2 = subplot('Position', [0.05 0.1 0.8 0.8]);
imhandle = imshow(IM);

barhandle = subplot('Position', [0.9 0.05 0.1 0.9]);
barhandle2 = bar(barhandle, 0);
barY = serdbg.vel;
set(barhandle2,'YDataSource','barY')
set(barhandle,'YLim', [-100 100]);

t = turret(serdbg);
t.set_state(turret.ST_CALIBRATE);

%Simulate calibration phase. 
for i=1:NFRAMES_CALIB_MAX
    IM = serdbg.next_frame(dt);
    set(imhandle, 'CData', IM);
    barY = serdbg.vel;
    refreshdata(barhandle);
    pause(1/FPS);
    t.step(IM, dt);
    
    %Break out when we wrap around
    if (t.state == turret.ST_BRAKE)
        break
    end
end

rmpath ../