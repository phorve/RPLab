% This script will ~hopefully~ read in multiple .tif files output from a
% custom lightsheet flourescence microscope and quantify the total
% flourescence at each time point through the following steps (described by
% Raghu): 
% 1. Reading in files, each stack into a 3D array
% 2. Setting a threshold -- "graythresh" , but also verify
% 3. Applying the threshold: "imbinarize" returns a binary image
% 4. Total intensity in the above threshold regions
%=========================================================================%
%=========================================================================%
% Initial Script written by PFH on 9 November 2021 
%=========================================================================%
%=========================================================================%
%% 1. Prompt setup for working directory
prompt = {'\fontsize{15} Please enter absolute path to parent directory (There should be a folder in this parent directory named "Fish1"):'}; 
opts.Interpreter = 'tex'; 
Title = 'Attention!'; 
defaultans = {''}; 
userpath = inputdlg(prompt,Title,[1 75], defaultans, opts);
%% 2. Initial Setup and prep for the rest of the script 
startpath = string(userpath);
cd (startpath); %path to the folder that holds all the .tif stacks 
fish='/Fish1';
cd './Fish1'
savename = "intensities";
extension=".mat";
%% 3. Count the number of timepoints that are present in this image acquisition 
all_files = dir;
all_dir = all_files([all_files(:).isdir]);
timepoints = numel(all_dir);

%% 4. Set the threshold for this dataset 
% I selected timepoint 29 (just under 5 hours of growth) since this is a consistent timepoint in every time series and is before the large biofilm aggregates begin to form.  
levelimg=imread(startpath+fish+"/Timepoint29/Pos1/zStack/GFP/Default/img_channel000_position000_time000000000_z200.tif");
levelimg_adj = imadjust(levelimg);
level = graythresh(levelimg_adj);
testimage = imbinarize(levelimg_adj,level);
imshow(testimage);
imshowpair(levelimg_adj, testimage, 'montage');
%% 5. Start looping through the timepoints 
for t = 1:timepoints
    disp("This is timepoint #"+t); % track the progress of the script 
    time=string(t); % make the timepoint something that we can use in a path 
    fileFolder = strcat(startpath,fish,"/Timepoint",time,"/Pos1/zStack/GFP/Default"); % where are all of our .tif files located? 
    filePattern = fullfile(fileFolder, '*.tif'); % the pattern of the files that we are interested in 
    all_tiff  = dir(filePattern); % make a list of all the .tif files for this timepoint 
    cd (fileFolder); % go that folder to actually start doing things with all of the .tif files 
    first_image = imread(all_tiff(1).name); % read in the first .tif image at this time point 
    [W,H] = size(first_image); % set the dimensions -- this could also be used to crop the images in the same location if needed 
    D = numel(all_tiff); % how many total tif files do we have in this  time point? 
    stack = zeros(W,H,D); % make our 3d stack object 
    stack(:,:,1) = first_image; % add our first image to the stack 
    for i = 2:D % cycle through all of the .tif files for this timepoint 
        img=imread(all_tiff(i).name); % read in the next image  
        img = imadjust(img); % adjust the min and max for the image (this may be causing problems) 
        total = sum(img(:)); % sum pixel intensity
        disp(total+"  is the overall intensity of the pixels") % display the sum pixel intensity for tracking purposes 
        %level = graythresh(img); % replaced this thresholding with the thresholding step in section 3 
        %thresholding up above 
        BW = imbinarize(img,level); % binarize
        imshowpair(img,BW,'montage'); % show the comparison between the two images 
        pixelcount = nnz(BW > level); % count pixels above the threshold 
        disp(pixelcount+" pixels above the auto-calculated threshold") % display how many pixels are above the threshold for tracking purposes 
        stack(:,:,i) = img; % add this image to the image stack 
        disp(string(i*100.0/D) + "%"); % for seeing the reading progress
        cd (startpath); % move back to
        save('intensities.mat', 'pixelcount', 'total', '-append');
        cd (fileFolder);
        disp("======================================================")
    end
    % movefile ('intensities.mat', 'intensities.mat'+time) % --> this is not
    % working but I want a way to rename the file for each timepoint to a
    % diffrerent names so we have a .mat file (or maybe a .txt file?)
    % for each time point instead of having one giant file 
end