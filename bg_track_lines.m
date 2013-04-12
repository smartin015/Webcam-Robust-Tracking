%TODO: Add crop feature to speed computation

function bg_track_lines(frame, action) 
    persistent bg_panorama;
    persistent pframe;
    persistent handlesDisp; %Displays background panorama
    persistent hlines;
    persistent h_pos;
    persistent IMSZ;
    
    if isempty(bg_panorama)
        IMSZ = size(frame);
        % set up background panorama
        pframe = frame;

        REPEAT = 5;
        bg_panorama = uint8(zeros(IMSZ(1), IMSZ(2)*REPEAT));
        handlesDisp = imshow(bg_panorama);

        bgsz = size(bg_panorama);
        fprintf('panorama init (%dx%d)\n', bgsz(2), bgsz(1));

        h_pos = IMSZ(2)/4; %Center of panorama

        hlines = (10:10:bgsz(1)-10)';
        fprintf('Tracking on %d lines\n', length(hlines));

        pause(0.01); %To get our frame to show up
        return
    end
    
    if (strcmp(action, 'train'))
        % Find maximal cross-correlation for each line.
        % These correspond to the best guess of movement for the given line.
        % TODO: Consider GPU-accelerated cross-correlation
        % See http://www.mathworks.com/help/signal/ref/xcorr.html
        maxlags = 10;
        x = arrayfun(@(i)({xcorr(pframe(i,:), frame(i,:), maxlags)}), hlines);
        c = cellfun(@(l)( find(l==max(l), 1) - maxlags - 1 ), x);

        %Estimate movement as median of estimates for each line
        h_pos = h_pos + median(c);

        %Average with current position image
        bg_panorama(:, ceil(h_pos):ceil(h_pos)+IMSZ(2)-1) = (bg_panorama(:, ceil(h_pos):ceil(h_pos)+IMSZ(2)-1) + frame) / 2;

        %show = step(inserter,bg_panorama,strips);
        set(handlesDisp,'CData',bg_panorama); 

        pframe = frame;
        
    elseif (strcmp(action, 'search')) 
        
    end
end
