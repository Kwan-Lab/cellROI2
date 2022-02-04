% This is Step 4 for processing calcium imaging data.
%
% After Step 3: ROI selection in Matlab GUI -->
% Take the selected ROI, go back to the motion-corrected image files, and extract signal
%
% AC Kwan, 11/19/2016

%% to do:
%% if grid_ROI, check if mean intensity is above 55% (might be changed later)
%% batch process

clearvars;
tic;
 
%% create directory structure for loading and saving files

%default values
default_scim_ver = '5';
default_root_dir = 'F:\GRABiCorre\893-02162021';
%default_scim_ver = '5';
%default_data_dir = '/Users/alexkwan/Desktop/ongoing data analysis/ROI extraction/testdata_resonant/';
default_reg_subdir = 'registered';
default_grid_roi = '0';  
default_batch_process = '0';

%ask user
prompt = {'ScanImage verison (3 or 5):','Root directory (for saving):','Subdirectory with registered .tiff images (to be analyzed):','Grid ROIs?','Batch Process?'};
dlg_title = 'Load ROIs and extract signals from registered images';
num_lines = 1;
defaultans = {default_scim_ver,default_root_dir,default_reg_subdir, default_grid_roi, default_batch_process};
answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
scim_ver=str2double(answer{1});
root_dir=answer{2};
reg_subdir=answer{3};
grid_roi = str2num(answer{4});
batch_process = str2num(answer{5});


if batch_process
    temp = dir(root_dir); %Edit to specify data directories
    data_dirs = {temp.name};
    temp = ~(strcmp(data_dirs,'.') | strcmp(data_dirs,'..'));
    data_dirs = data_dirs(temp); %remove '.' and '..' from directory list
    disp('Directories for movement correction:');
    disp(data_dirs');
else
    data_dirs{1} = root_dir;
    disp('Directories for movement correction:');
    disp(data_dirs);
end    
    % get all sub directories
    
% h=msgbox('Select the directory with reference ROI .mat files');
% uiwait(h);
% save_dir=uigetdir(data_dir,'Select the directory with reference ROI .mat files');

%% load the ROI masks
for jj = 1:length(data_dirs)
    
    if batch_process
        curr_dir = fullfile(root_dir,data_dirs{jj});
    else
        curr_dir = root_dir;
    end
    % get the directory with ROI masks
    temp = dir(fullfile(curr_dir,'*ROI*'));
    save_dir = temp([temp.isdir]==1).name;
    
    cd(fullfile(curr_dir,save_dir));
    roifiles=dir('cell*.mat');  % there is another roiData.mat file in cellROI2.0
    
    cellmask=[];
    for k=1:numel(roifiles)
        load(roifiles(k).name);
        
        cellmask(:,:,k)=bw;
        if grid_roi  % no need to calculate neuropil signal for grid rois
            neuropilmask(:,:,k) = 0;
        else
            neuropilmask(:,:,k)=subtractmask;
        end
        %isred(k)=isRedCell;   % no red channels
    end
    clear bw subtractmask;
    
    %% do we want to shift the ROI masks in x,y (e.g. use same masks for longitudinal data)
    % no need to nudge for now, plot the grid on mean projection
     nudge=1;
    curr_x=0; curr_y=0; curr_contrast=1;
    %meanprojpic=[];
    cd(curr_dir);
    meanProjPath = dir('*mean*.tif');
%     
%     while (nudge==1)
%         choice = questdlg('Would you like to nudge the x-y position of the ROIs?', ...
%             'Moving the ROIs', ...
%             'Yes, let me nudge (again)','No, the ROIs are good','No, the ROIs are good');
%         switch choice
%             case 'Yes, let me nudge (again)'
%                 nudge = 1;
%             case 'No, the ROIs are good'
%                 nudge = 0;
%         end
%         
        if nudge==1
            %if no image loaded, ask for mean projection image
            if ~isempty(meanProjPath)
                meanProj = loadtiffseq([],meanProjPath.name);
            
            
            %ask user how much to nudge the ROIs
            default_x = int2str(curr_x);
            default_y = int2str(curr_y);
            default_contrast = int2str(curr_contrast);
            
%             prompt = {'x:','y:','Image contrast:'};
%             dlg_title = 'Nudging the ROIs with respect to the images';
%             num_lines = 1;
%             defaultans = {default_x,default_y,default_contrast};
%             answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
%             curr_x=str2num(answer{1});
%             curr_y=str2num(answer{2});
%             curr_contrast=str2num(answer{3});
            
            %below: show how the nudged ROIs align with the figure
            close;
            figure;
            
            %color map for the image, use a smooth gray scale
            graymap=[linspace(0,1,255); linspace(0,1,255); linspace(0,1,255)]';
            
            %re-scale pixel values so they range from 0 to 255
            temppic=double(meanProj);    %convert to double so can multiple/divide with more precision
            temppic=255*temppic./nanmax(temppic(:));    %re-scale pixel values so range 0 to 255
            temppic=temppic*curr_contrast;  %if user desires enhanced contrast
            temppic(temppic>255)=255;       %if pixel values exceeds max possible, then set to max
            
            image(temppic);
            colormap(graymap);
            axis tight; axis square;
            hold on;
            for j=1:numel(roifiles)
                
                %shifts it by x and y, pad the rest with zero
                shifted_cellmask=shiftMask(cellmask(:,:,j),curr_x,curr_y);
                
                if (sum(shifted_cellmask(:))>0) %if the ROIs encompasses any pixels
                    %draw ROI outline
                    [B,L]=bwboundaries(shifted_cellmask,'noholes');
                    plot(B{1}(:,2),B{1}(:,1),'r','LineWidth',1);
                    % label the grid number
                    
                else
                    disp(['ROI ' int2str(j) ' is completely out of the imaging frame']);
                end
            end
            title(['Number of ROIs=' int2str(numel(roifiles)) '; x-shift=' int2str(curr_x) '; y-shift=' int2str(curr_y)]);
            set(0,'defaultfigureposition',[40 40 800 1000]);
            cd(curr_dir);
            print(gcf,'-dpng','loadxysavefluo.png');
            
%             h=msgbox('Check the alignment between the nudged ROIs and projection image');
%             uiwait(h);
        end
%     end
    
    %save the ROI figure
    print(gcf,'-dpng','ROI-projection');
        end
    %%
    shifted_cellmask=nan(size(cellmask));
    shifted_neuropilmask=nan(size(neuropilmask));
    for k=1:numel(roifiles)
        %shifts it by x and y, pad the rest with zero
        shifted_cellmask(:,:,k)=shiftMask(cellmask(:,:,k),curr_x,curr_y);
        if ~grid_roi
            shifted_neuropilmask(:,:,k)=shiftMask(neuropilmask(:,:,k),curr_x,curr_y);
        end
    end
    
    %% load the mean projection, calculate the ROI intensity distribution
    if ~isempty(meanProjPath)
    meanProjPath = dir('*mean*.tif');
    meanProj = loadtiffseq([],meanProjPath.name);
    
    % get the mean intensity in ROI
    meanIntensity = zeros(1, size(cellmask,3));
    for uu = 1:size(cellmask,3)
        meanIntensity(uu) = mean(meanProj(cellmask(:,:,uu)==1));
    end
    figure; histogram(meanIntensity);
    
    % remove the rois with mean intensity under 10% percentile
    roiRMmask = meanIntensity<=prctile(meanIntensity, 10);
    
    % plot the ROI after removal
    figure;
    
    %color map for the image, use a smooth gray scale
    graymap=[linspace(0,1,255); linspace(0,1,255); linspace(0,1,255)]';
    
    %re-scale pixel values so they range from 0 to 255
    temppic=double(meanProj);    %convert to double so can multiple/divide with more precision
    temppic=255*temppic./nanmax(temppic(:));    %re-scale pixel values so range 0 to 255
    temppic=temppic*curr_contrast;  %if user desires enhanced contrast
    temppic(temppic>255)=255;       %if pixel values exceeds max possible, then set to max
    
    image(temppic);
    colormap(graymap);
    axis tight; axis square;
    hold on;
    for j=1:numel(roifiles)
        
        %shifts it by x and y, pad the rest with zero
        
        if (sum(sum(shifted_cellmask(:,:,j)))>0)   % plot remaining ROIs
            %draw ROI outline
            [B,L]=bwboundaries(shifted_cellmask(:,:,j),'noholes');
            plot(B{1}(:,2),B{1}(:,1),'r','LineWidth',1);
            if roiRMmask(j) == 0
                hold on;
                text(B{1}(1,2),B{1}(1,1),num2str(j),'Color','red','FontSize',15);
            end
        else
            disp(['ROI ' int2str(j) ' is completely out of the imaging frame']);
        end
    end
    title(['Number of ROIs=' int2str(numel(roifiles)) '; x-shift=' int2str(curr_x) '; y-shift=' int2str(curr_y)]);
    set(0,'defaultfigureposition',[40 40 800 1000]);
    cd(curr_dir);
    print(gcf,'-dpng','analyzed_rois.png');
    
    end
    %% get the signal from the reg image files or mat files if available
    
    % remove roi with lower intensity later
    
    cd(curr_dir);
    mat_subdir = 'mat';
    
    if isdir(mat_subdir)
        cd(mat_subdir);
        if ~exist('ROI','dir')
            stacks = dir('*.mat');
            f=cell(numel(roifiles),1); n=cell(numel(roifiles),1);
            for j=1:numel(stacks)
                disp(['Loading reg image file ' stacks(j).name]);
                cd(fullfile(curr_dir,mat_subdir));
                pic=load(stacks(j).name);
                [nY nX nZ]=size(pic.stack);
                
                parfor k=1:numel(roifiles)
                    tempf=[]; tempn=[];
                    for i=1:1:nZ
                        %get sum of pixel values within the ROI
                        tempf(i)=sum(sum(pic.stack(:,:,i).*uint16(shifted_cellmask(:,:,k))));
                        tempn(i)=sum(sum(pic.stack(:,:,i).*uint16(shifted_neuropilmask(:,:,k))));
                    end
                    if sum(sum(shifted_cellmask(:,:,k)))>0     %if there are pixels belonging the the ROI
                        if j==1 %if this is the first reg image, then start new variables
                            f{k}=tempf/sum(sum(shifted_cellmask(:,:,k)));   %per-pixel fluorescence
                            n{k}=tempn/sum(sum(shifted_neuropilmask(:,:,k)));   %per-pixel fluorescence
                        else
                            f{k}=[f{k} tempf/sum(sum(shifted_cellmask(:,:,k)))];   %per-pixel fluorescence
                            n{k}=[n{k} tempn/sum(sum(shifted_neuropilmask(:,:,k)))];   %per-pixel fluorescence
                        end
                    else %if the ROI is outside of the imaging field of view
                        f{k}=nan(size(tempf));
                        n{k}=nan(size(tempn));
                    end
                end
                clear pic;
            end
        end
    else
        cd(reg_subdir);
        stacks=dir('*.tif');
        if ~exist('ROI','dir')
            f=[]; n=[];
            for j=1:numel(stacks)
                disp(['Loading reg image file ' stacks(j).name]);
                cd(fullfile(curr_dir,reg_subdir));
                warning('off','all');   %scim_openTif generates warning
                pic=loadtiffseq([],stacks(j).name);
                warning('on','all');   %scim_openTif generates warning
                [nY nX nZ]=size(pic);
                
                parfor k=1:numel(roifiles)
                    tempf=[]; tempn=[];
                    for i=1:1:nZ
                        %get sum of pixel values within the ROI
                        tempf(i)=sum(sum(pic(:,:,i).*uint16(shifted_cellmask(:,:,k))));
                        tempn(i)=sum(sum(pic(:,:,i).*uint16(shifted_neuropilmask(:,:,k))));
                    end
                    if sum(sum(shifted_cellmask(:,:,k)))>0     %if there are pixels belonging the the ROI
                        if j==1 %if this is the first reg image, then start new variables
                            f{k}=tempf/sum(sum(shifted_cellmask(:,:,k)));   %per-pixel fluorescence
                            n{k}=tempn/sum(sum(shifted_neuropilmask(:,:,k)));   %per-pixel fluorescence
                        else
                            f{k}=[f{k} tempf/sum(sum(shifted_cellmask(:,:,k)))];   %per-pixel fluorescence
                            n{k}=[n{k} tempn/sum(sum(shifted_neuropilmask(:,:,k)))];   %per-pixel fluorescence
                        end
                    else %if the ROI is outside of the imaging field of view
                        f{k}=nan(size(tempf));
                        n{k}=nan(size(tempn));
                    end
                end
                clear pic;
            end
        end
    end
    
    %% save the extracted signals
    cd(curr_dir);
    
    
    if isdir(mat_subdir)
        cd(mat_subdir);
    else
        cd(reg_subdir);
    end
    
    if ~exist('ROI','dir')
        [~,~,~]=mkdir('ROI');
        cd('ROI');
        for k=1:numel(roifiles)
            cellf=f{k};
            neuropilf=n{k};
            bw=shifted_cellmask(:,:,k);
            subtractmask=shifted_neuropilmask(:,:,k);
            %isRedCell=isred(k);
            
            temp = sprintf('%03d',k);
            save(strcat('cell',temp,'.mat'),'cellf','neuropilf','bw','subtractmask');
        end
    end
    disp(['Processed ' int2str(numel(roifiles)) ' ROIs --- All done!']);
    close all;
end
%%
% figure;
% subplot(2,1,1);
% plot(cellf);
% axis tight; title('downsampled');
% subplot(2,1,2);
% plot(f{numel(roifiles)});
% axis tight; title('extracted');


