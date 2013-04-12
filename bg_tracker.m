classdef bg_tracker < handle
   properties 
       bg_panorama;
       pframe;
       handlesDisp;
       hlines;
       h_pos;
   end 
   properties(Constant = true)
       REPEAT = 5;
       LINE_SPACING = 10;
       HORIZ_SEARCH_DIST = 10;
       STARTPOS = 50;
   end
   methods  
       function o = bg_tracker(initial_frame)
            IMSZ = size(initial_frame);
            
            % set up background panorama
            o.pframe = initial_frame;
            o.bg_panorama = uint8(zeros(IMSZ(1), IMSZ(2)*o.REPEAT));
            o.handlesDisp = imshow(o.bg_panorama);

            bgsz = size(o.bg_panorama);
            fprintf('panorama init (%dx%d)\n', bgsz(2), bgsz(1));

            o.h_pos = IMSZ(2)/4; %Center of panorama

            o.hlines = (10:10:bgsz(1)-10)';
            fprintf('Tracking on %d lines\n', length(o.hlines));
       end
       
       
       function track(o, frame)
        IMSZ = size(frame);
        % Find maximal cross-correlation for each line.
        % These correspond to the best guess of movement for the given line.
        % TODO: Consider GPU-accelerated cross-correlation
        % See http://www.mathworks.com/help/signal/ref/xcorr.html
        
        x = arrayfun(@(i)({xcorr(o.pframe(i,:), frame(i,:), o.HORIZ_SEARCH_DIST)}), o.hlines);
        c = cellfun(@(l)( find(l==max(l), 1) - o.HORIZ_SEARCH_DIST - 1 ), x);

        %Estimate movement as median of estimates for each line
        o.h_pos = o.h_pos + median(c);

        %Average with current position image
        o.bg_panorama(:, ceil(o.h_pos):ceil(o.h_pos)+IMSZ(2)-1) = (o.bg_panorama(:, ceil(o.h_pos):ceil(o.h_pos)+IMSZ(2)-1) + frame) / 2;

        %show = step(inserter,bg_panorama,strips);
        set(o.handlesDisp,'CData',o.bg_panorama); 

        o.pframe = frame;
         
       end
       
       function crop(o)
          disp('TODO: IMPLEMENT'); 
       end
       
       function search(o, frame)
          disp('TODO: IMPLEMENT'); 
       end
   end
   
end
