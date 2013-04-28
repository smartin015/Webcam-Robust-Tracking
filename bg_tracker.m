classdef bg_tracker < handle
    % This class handles background scene construction. Once the 
    % background panorama (bg_panorama) is constructed, 
   properties 
       bg_panorama;
       pframe;
       handlesDisp;
       hlines;
       h_pos;
       endpos;
       imsz;
       first;
       rot_to_px;
   end 
   properties(Constant = true)
       REPEAT = 5; %bg_panorama width is REPEAT * <image width>
       LINE_SPACING = 10; %Horizontal xcorr line spacing
       HORIZ_SEARCH_DIST = 10; %maxlag for xcorr
       STARTPOS = 50; %Panorama starting offset from left of bg_panorama
       CROP_THRESH = 5; %Bit extra pixels to ensure image match
       WRAP_THRESH = 16; %Mean pixel difference between wrapped frames
       VEL_PERSIST = 0.9; %Proportion of influence of old velocity values
       EST_WEIGHT  = 0.5; %Weight of estimated value versus cross-correlation
   end
   methods  
       function o = bg_tracker(initial_frame)
            o.imsz = size(initial_frame);
            o.rot_to_px = 10; %px/radian
            
            
            % set up background panorama
            o.pframe = initial_frame;
            o.first = initial_frame;
            o.bg_panorama = uint8(128 .* ones(o.imsz(1), o.imsz(2)*o.REPEAT));
            figure();
            o.handlesDisp = imshow(o.bg_panorama, 'InitialMagnification', 'fit');

            bgsz = size(o.bg_panorama);
            fprintf('panorama init (%dx%d)\n', bgsz(2), bgsz(1));

            o.h_pos = o.STARTPOS; %Center of panorama
            o.endpos = -1;

            o.hlines = (10:10:bgsz(1)-10)';
            fprintf('Tracking on %d lines\n', length(o.hlines));
       end
       
       function save(o, path)
          %Save background tracking info to file
          data = struct();
          data.bg_panorama  = o.bg_panorama;
          data.h_pos        = o.h_pos;
          data.endpos       = o.endpos;
          data.imsz         = o.imsz;
          data.pframe       = o.pframe; 
          data.rot_to_px    = o.rot_to_px; %#ok<STRNU>
          save(path, 'data');
       end
       
       function o = loadexisting(o, path)
          %Load background tracking info from file
          load(path);
          o.bg_panorama     = data.bg_panorama;
          o.h_pos           = data.h_pos;
          o.endpos          = data.endpos;
          o.imsz            = data.imsz;
          o.pframe          = data.pframe;
          o.rot_to_px       = data.rot_to_px;
       end
       
       function [dist, c] = correlate(o, im1, im2, searchdist)
           % Find maximal cross-correlation for each line.
           % These correspond to the best guess of movement for the given line.
           % TODO: Consider GPU-accelerated cross-correlation
           % See http://www.mathworks.com/help/signal/ref/xcorr.html
           x = arrayfun(@(i)({xcorr(im1(i,:), im2(i,:), searchdist)}), o.hlines);
           c = cellfun(@(l)( find(l==max(l), 1) - searchdist - 1 ), x);
           
           if (nnz(c == 0) < 0.8 * length(c)) %Significantly nonzero - remove bias.
            c = c(not(c == 0));
           end
           [dist,F] = mode(c);
           
           if (F < 3) %If mode insignificant, use median
               dist = median(c);
           end
       end
       
       function [rot_delta] = estimate_shift(o, frame, rot_delta)
           %Calculate position change and update h_pos
           xc_dist = o.correlate(o.pframe, frame, o.HORIZ_SEARCH_DIST);
           est_dist = rot_delta * o.rot_to_px;
           
           %Result distance factors in estimate and cross-correlation
           dist = o.EST_WEIGHT*est_dist + (1-o.EST_WEIGHT)*xc_dist;
           o.h_pos = o.h_pos + dist;
           
           rot_delta = dist / o.rot_to_px; %Convert back to rotation units
           o.pframe = frame;
       end
       
       function [overlapped] = calibrate(o, frame, rot_delta)
           
        %Calculate position change and update h_pos
        dist = o.correlate(o.pframe, frame, o.HORIZ_SEARCH_DIST);
        o.h_pos = o.h_pos + dist;
        o.rot_to_px = o.VEL_PERSIST * o.rot_to_px + (1-o.VEL_PERSIST) * (dist / rot_delta); %Update d_pixel/d_pos

        %Average new image with current position image
        o.bg_panorama(:, ceil(o.h_pos):ceil(o.h_pos)+o.imsz(2)-1) = wfusmat(o.bg_panorama(:, ceil(o.h_pos):ceil(o.h_pos)+o.imsz(2)-1), frame, 'mean');
        
        %show = step(inserter,bg_panorama,strips);
        set(o.handlesDisp,'CData',o.bg_panorama); 

        o.pframe = frame;
        
        % 'Overlap' is image frame at least one full image length
        % away that has a mean pixel difference below threshold.
        overlapped = (o.h_pos > o.STARTPOS + o.imsz(2) && mean(mean(o.first - frame)) < o.WRAP_THRESH);
       end
       
       function crop(o)
          %Match end to start (modified from track function)
          o.endpos = round(o.h_pos);
          endClip  = o.bg_panorama(:, o.endpos:o.endpos+o.imsz(2)-1);
          toSearch = o.bg_panorama(:, o.STARTPOS:o.STARTPOS+o.imsz(2)-1);
          shift = o.correlate(toSearch, endClip, 50);
          o.endpos = o.h_pos - shift;
          
          %Confirm good correlation (TODO: Make only debug mode)
          startIM = o.bg_panorama(:,o.STARTPOS:o.STARTPOS + o.imsz(2) -1);
          endIM = o.bg_panorama(:, o.endpos:o.endpos + o.imsz(2) -1);
          fprintf('Crop correlation: %0.2f\n', mean(mean(startIM - endIM)));
          
          % Crop unused part of panorama
          crop_start = o.STARTPOS - o.CROP_THRESH;
          crop_end = o.endpos + o.imsz(2) + o.CROP_THRESH;
          o.bg_panorama = o.bg_panorama(:, crop_start:crop_end);
          
          o.h_pos = o.h_pos - crop_start;
          o.endpos = o.endpos - crop_start;
          
          shapeInserter = vision.ShapeInserter;
          rectangle = int32([o.CROP_THRESH 1 o.imsz(2) o.imsz(1);  ...
                             o.endpos 1 o.imsz(2) o.imsz(1)]);
          show = step(shapeInserter, o.bg_panorama, rectangle);
          o.handlesDisp = imshow(show, 'InitialMagnification', 'fit');
       end
       
       function [offs, c] = search(o, frame)
          %Search entire background for match to frame
          [offs, c] = o.correlate(o.bg_panorama, frame, length(o.bg_panorama));
          offs = offs - o.CROP_THRESH + 1;
          
          %Negative values should wrap around
          if (offs <= 0)
              offs = offs + o.endpos - o.CROP_THRESH;
          end
       end
       
       function [IM] = pull_bg_section(o, pos)
          % Creates a camera-view image at panorama position
          IM = o.bg_panorama(:, pos: pos + o.imsz(2) - 1);
       end
       
       function [IM] = get_frame(o)
           IM =  o.pull_bg_section(round(o.h_pos));
       end
       
   end
   
end
