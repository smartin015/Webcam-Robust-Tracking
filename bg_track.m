function bg_track(frame) 
    persistent bg_panorama;
    persistent cam_pos;
    persistent handlesDisp; %Displays background panorama
    
    IMSZ = size(frame);
    if isempty(bg_panorama)
        % set up background panorama
        bg_panorama = uint8(zeros(IMSZ(1)*2, IMSZ(2)*2));
        bgsz = size(bg_panorama);
        fprintf('panorama init (%dx%d)\n', bgsz(2), bgsz(1));
        cam_pos = [IMSZ(1)/2 IMSZ(2)/2]; %Upper left corner of camera in bg_panorama 
        handlesDisp = imshow(bg_panorama);
        return
    end
    
    %Calculate blurriness. If blurry, don't add to background
    
    
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
    
    
    
    bg_panorama(cam_pos(1):cam_pos(1)+IMSZ(1)-1, cam_pos(2):cam_pos(2)+IMSZ(2)-1) = frame;
    
    
    set(handlesDisp,'CData',bg_panorama); 
end