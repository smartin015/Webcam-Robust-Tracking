function bg_track(frame) 
    persistent bg_panorama;
    persistent cam_pos;
    persistent pframe;
    persistent handlesDisp; %Displays background panorama
    persistent rectInserter;
    
    IMSZ = size(frame);
    if isempty(bg_panorama)
        % set up background panorama
        pframe = frame;
        bg_panorama = uint8(zeros(IMSZ(1)*2, IMSZ(2)*2));
        bgsz = size(bg_panorama);
        fprintf('panorama init (%dx%d)\n', bgsz(2), bgsz(1));
        cam_pos = [IMSZ(1)/2 IMSZ(2)/2]; %Upper left corner of camera in bg_panorama 
        %cam_pos = [1 1];
        handlesDisp = imshow(bg_panorama);
        rectInserter = vision.ShapeInserter('Shape','Rectangles');
        return
    end
    
    
    %{
    %Attempt to match corner motion
    N_CORNERS = 10;
    C_new = corner(frame, N_CORNERS); %
    
    %Reject corners on the corners
    C_new =  mat2cell(C_new, ones(1,10), 2); %Pick 10 random corners
    THRESH = 5;
    C_new_reject = cellfun(@(p)(p(1) <= THRESH || p(2) <= THRESH || p(1) >= IMSZ(1)-THRESH || p(2) >= IMSZ(2)-THRESH), C_new); 
    C_new = C_new(not(C_new_reject));
    
    if (isempty(C_new))
        disp('No corners found');
        return;
    end
    
    new_chunks = cellfun(@(p)({frame(p(1)-THRESH:p(1)+THRESH, p(2)-THRESH:p(2)+THRESH)}),C_new);
    bg_chunks = cellfun(@(p)({bg_panorama(p(1)-5:p(1)+5, p(2)-5:p(2)+5)}),C_new);
    
    disp(sum(sum(new_chunks{1} - bg_chunks{1})));
    %}
    
    rectangle = int8([50 50 120 120]);
    sample = imcrop(frame, rectangle);
    psample = imcrop(pframe, rectangle);
    corn = corner(sample);
    pcorn = corner(psample);
    pcorn_fixed = zeros(length(corn), 2);
    for i=1:length(corn)
        distances = arrayfun(@(j)(norm(pcorn(j,:) - corn(i,:))), 1:length(pcorn));
        mindists = find(distances == min(distances));
        pcorn_fixed(i,:) = pcorn(mindists(1),:);
    end
    %Get mean distance
    displacement = mean(corn - pcorn_fixed);
    %cam_pos = round(cam_pos - displacement);
    %Want to find closest value for each corn
    %{
    %Run LK to get estimation of motion direction
    uv = lucas_kanade(double(psample), double(sample));
    disp(uv);
    
    uv = uv .* 10;
    rectangle(1) = rectangle(1) + uv(1);
    rectangle(3) = rectangle(3) + uv(1);
    rectangle(2) = rectangle(2) + uv(2);
    rectangle(4) = rectangle(4) + uv(2);
    %}
    
    %TODO: Calculate blurriness. If too blurry, don't add to background
    
    bg_panorama(cam_pos(1):cam_pos(1)+IMSZ(1)-1, cam_pos(2):cam_pos(2)+IMSZ(2)-1) = frame;
    
    
    show = step(rectInserter,bg_panorama,rectangle);
    set(handlesDisp,'CData',show); 
    pframe = frame;
end
