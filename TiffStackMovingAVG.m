function [data_out] = TiffStackMovingAVG(tiff_file, bin_size)
%% TiffStackMovingAVG.m
% /~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~/
% /~~~~~~~~~~~~~~~~~~~~~~ TIFF STACK MOVING AVERAGE ~~~~~~~~~~~~~~~~~~~~~~/
% /~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~/
% / description:
% /     Take an input stack (.tiff) and create a moving average.
% / 
% / inputs:
% /     <tiff_file> :   full path to input image (.tiff)
% /     <bin_size>  :   size of moving average window (in frames)
% / 
% / outputs:
% /     <data_out>   :   output stack data
% / 
% / notes:
% /     - an ouput .tiff is created in folder containing <tiff_in> using
% /     the input file's basename as a template.
% / 
% /~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~/
% / 20210927 $nks @ $kwanlab                                              /
% /~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~/

% inputs
[filepath, filename, fileext] = fileparts(tiff_file);
bin_size = bin_size;

% output naming
out_file = fullfile(filepath, strcat(filename, ['_movingAVGby' num2str(bin_size) 'frames'], fileext));

%% load data

disp(['Loading ' tiff_file]);

% img info
tiff_info = imfinfo(fullfile(filepath, strcat(filename, fileext)));

% pre-define data matrix
dat = zeros(tiff_info(1).Height, tiff_info(1).Width, size(tiff_info, 1), 'int16');

% load data
dat = loadtiffseq(filepath, strcat(filename, fileext));

%% get moving average

disp(['Calculating moving average...']);

data_out = zeros(size(dat, 1), size(dat, 2), ceil(size(dat, 3)/bin_size), 'uint16');
for i = 1:size(data_out, 3)
    if i == size(data_out, 3)
        data_out(:, :, i) = mean(dat(:, :, (((i - 1) * bin_size) + 1):end), 3);
    else
        data_out(:, :, i) = mean(dat(:, :, (((i - 1) * bin_size) + 1):(i * bin_size)), 3);
    end
end

%% save output

disp(['Saving output to: ' out_file]);

% % save moving average tif file
% saveTiff(data_out, new_tiff_info, out_file); % seems saveTiff image-stack-processing function fails to get all the necessary tags needed to construct new .tif that is loadable by other programs (nks 20210927)
t = Tiff(out_file, 'w');
tagstruct.ImageLength = size(data_out, 1); % image height
tagstruct.ImageWidth = size(data_out, 2); % image width
tagstruct.Photometric = Tiff.Photometric.MinIsBlack; % https://de.mathworks.com/help/matlab/ref/tiff.html
tagstruct.BitsPerSample = 16;
tagstruct.SamplesPerPixel = 1;
tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky; % groups rgb values into a single pixel instead of saving each channel separately for a tiff image
tagstruct.Software = 'MATLAB';
setTag(t, tagstruct)
t.write(data_out(:, :, 1));
for j = 2:size(data_out, 3) %create write dir, tag, and write subsequent frames
    t.writeDirectory();
    t.setTag(tagstruct);
    t.write(data_out(:, :, j));
end
t.close(); %%% this is necessary otherwise you won't be able to open it in imageJ etc to double check, unless you close matlab

