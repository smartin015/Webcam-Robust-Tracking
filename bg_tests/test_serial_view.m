%Tests capability of serial_debug class in receiving
%serial commands and affecting a test view using the
%settings provided by those commands.

clear functions
clear serdbg
addpath ../


ts = 0;
pan = rgb2gray(imread('sonycenter.png'));
serdbg = serial_view_emulator(pan);
IM = serdbg.next_frame(ts);
h2 = subplot('Position', [0.05 0.1 0.8 0.8]);
imhandle = imshow(IM);

barhandle = subplot('Position', [0.9 0.05 0.1 0.9]);
barhandle2 = bar(barhandle, 0);
barY = serdbg.vel;
set(barhandle2,'YDataSource','barY')
set(barhandle,'YLim', [-128 128]);

%Simulate calibration phase. 
NFRAMES = 1000;
FPS = 22;
dt = 1000/FPS;
ts = 0;
for i=1:NFRAMES
    ts = ts + dt;
    v = int8(127 * sin((2*pi/25)*ts / 1000)); %1 cycle/ 10 sec
    serdbg.write(bitset(v, 1, 0));
    IM = serdbg.next_frame(dt);
    set(imhandle, 'CData', IM);
    barY = serdbg.vel;
    refreshdata(barhandle);
    pause(1/FPS);
end

rmpath ../