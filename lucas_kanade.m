function [uv] = Lucas_Kanade(I_t, I_t1)
% INPUT
% I_t Image at time t
% R coordinate of the rectangle (ROI) to track in I t
% I_t1 Image at time t+1
%
% OUTPUT
% u x-coordinate shift so that the error in I t1 is minimized
% v y-coordinate shift
%
% Note that x and y coordinate shifts are calculated to the nearest pixel.
%
% Scott Martin <semartin>

%Compute gradients
[Ix, Iy] = gradient(I_t1);
It = (I_t1 - I_t);

%Construct system of linear equations
%A = [Ix Iy], b = [It], x = [u;v]
%Ax = -b
winsz = size(Ix,1)*size(Ix,2);
b = squeeze(reshape(It, [winsz 1 1]));
Ax = squeeze(reshape(Ix, [winsz 1 1]));
Ay = squeeze(reshape(Iy, [winsz 1 1]));
A = [Ax Ay];

%Solve least-squares (could use SVD for optimization)
uv = inv(A' * A) * A' * (-b);

end