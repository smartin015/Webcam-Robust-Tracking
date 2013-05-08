% Detect foreground objects using subtraction with blur, 
% threshold, area opening and hole filling.
% Scott Martin <semartin@andrew.cmu.edu>
% 5/2013
function [fg_mask, fg_props] = detect_objects(fg_img, bg_img)
    %Empirical value. Differences above this could be foreground.
    DIFF_THRESH = 32;
    AREA_THRESH = 1768; %Remove blobs smaller than this size
    TOOBIG_THRESH = 10000; %Remove blobs bigger than this size
    
    %TODO: Histogram equalization of the two images
    
    %Subtract and blur a bit
    diff = double(fg_img) - double(bg_img);
    H = fspecial('gaussian',10,5);
    %TODO: Gaussian on abs value?
    diff = imfilter(diff,H,'replicate');
    
    %TODO: Select pixels with maximal difference?
    
    %Get all values within threshold, remove noisy bits
    fg_mask = (abs(diff) > DIFF_THRESH);
    fg_mask = bwareaopen(fg_mask, AREA_THRESH);
    fg_mask = fg_mask & ~bwareaopen(fg_mask, TOOBIG_THRESH);
    fg_mask = ~bwareaopen(~fg_mask, 100); %Fills in holes (Better than imfill)
    %imfill(fg_mask, 8, 'holes');
    
    %Label the sections
    fg_labels = bwlabel(fg_mask,8); 
    fg_props = regionprops(fg_labels,'basic'); 
end