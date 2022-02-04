function shifted_cellmask = shiftMask(curr_cellmask,curr_x,curr_y)
% % shiftMask %
%PURPOSE:   Takes a bitmap mask, shifts it by x and y, pad the rest with zero
%AUTHORS:   AC Kwan 170518
%
%INPUT ARGUMENTS
%   curr_cellmask:  The original bitmap mask
%   curr_x:         How much to shift in x
%   curr_y:         How much to shift in y
%
%OUTPUT ARGUMENTS
%   shifted_cellmask:      The shifted bitmap mask

if curr_y>0     %shift y and pad the rest with zero
    tempcellmask=[zeros(curr_y,size(curr_cellmask,2)); curr_cellmask(1:end-curr_y,:)];
elseif curr_y<0
    tempcellmask=[curr_cellmask(1+(-1*curr_y):end,:); zeros(-1*curr_y,size(curr_cellmask,2))];
else
    tempcellmask=curr_cellmask;
end

if curr_x>0     %shift x and pad the rest with zero
    shifted_cellmask=[zeros(size(tempcellmask,1),curr_x) tempcellmask(:,1:end-curr_x)];
elseif curr_x<0
    shifted_cellmask=[tempcellmask(:,1+(-1*curr_x):end) zeros(size(tempcellmask,1),-1*curr_x)];
else
    shifted_cellmask=tempcellmask;
end