
%Load saved tracker session to get panorama
load('tracker.mat')

hpos = 330;
WIDTH = data.imsz(2);

%Pull out bg and fgimage (slight offset)
bg_img = data.bg_panorama(:, hpos:hpos+WIDTH-1);
fg_img = data.bg_panorama(:, hpos+1:hpos+WIDTH);

%Apply object for fg image
inserter = vision.ShapeInserter('Shape','Circles','Fill', true, 'Opacity', 1.0);
circ_pos = uint16([120 120 20; ...
                   230 230 15; ...
                   70  150 30]);
fg_img = step(inserter, fg_img, circ_pos);
    
%Add noise (different versions, as if different frames)
bg_img = imnoise(bg_img, 'gaussian');
fg_img = imnoise(fg_img, 'gaussian');

%Subtract background
[fg_mask, props] = detect_objects(fg_img, bg_img);
imshow(fg_mask);

%centroids = cat(1, props.Centroid)
hold on
for i=1:length(props)
    %plot(props(i).Centroid(1), props(i).Centroid(2), 'r+');
    rectangle('Position', props(i).BoundingBox, 'EdgeColor', 'g');
    text(props(i).Centroid(1), props(i).Centroid(2), int2str(i));
end
hold off;



