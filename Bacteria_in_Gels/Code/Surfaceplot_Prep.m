% This script reads in multiple .tif files output from a
% custom lightsheet flourescence microscope and creates image image stacks
% then calculates the sum of all slices in the Z direction to in
% preparation to create surface plots 

%=========================================================================%
% Patrick Horve + Raghu Parthasarathy - Fall 2021
%=========================================================================%

% Prompt setup for working directory
clear
prompt = {'\fontsize{15} Please enter absolute path to parent directory (There should be a folder in this parent directory named "Fish1"):'};
opts.Interpreter = 'tex';
Title = 'Attention!';
defaultans = {''};
userpath = inputdlg(prompt,Title,[1 75], defaultans, opts);
%=========================================================================%
%=========================================================================%
% Initial Setup and prep for the rest of the script
startpath = string(userpath);
cd (startpath); %path to the folder that holds all the .tif stacks
mkdir("surfaceplot_stacks_levelsubtract")
mkdir("surfaceplot_stacks_meansubtract")

% Start looping through the timepoints and create our .mat files by subtracting the threshold or the mean 
output = table;
for t = 1:timepoints 
    disp("This is timepoint #"+t); % track the progress of the script
    time=string(t); % make the timepoint something that we can use in a path
    fileFolder = strcat(startpath,fish,"/Timepoint",time,"/Pos1/zStack/GFP/Default"); % where are all of our .tif files located?
    filePattern = fullfile(fileFolder, '*.tif'); % the pattern of the files that we are interested in
    all_tiff  = dir(filePattern); % make a list of all the .tif files for this timepoint
    cd (fileFolder); % go that folder to actually start doing things with all of the .tif files
    first_image = imread(all_tiff(1).name); % read in the first .tif image at this time point
    first_image = imrotate(first_image, -90);
    [W,H] = size(first_image); % set the dimensions -- this could also be used to crop the images in the same location if needed
    D = (numel(all_tiff)); % how many total tif files do we have in this  time point?
    stack = zeros(W,H,D); % make our 3d stack object
    stack(:,:,1) = first_image; % add our first image to the stack
    for i = 2:D % cycle through all of the .tif files for this timepoint and make a 3d array with all of the .tif files at this timpoint
        img=imread(all_tiff(i).name); % read in the next image
        img = imrotate(img, -90);
        stack(:,:,i) = img; % add this image to the image stack
        disp(string(i*100.0/D) + "% of the images from this timepoint added to the 3D array"); % for seeing the reading progress
    end
    % Cropping (manual)
     % fprintf('Original x, y, z sizes: %d (x), %d (y), %d(z).\n', ...
     %     size(stack,2), size(stack,1), size(stack,3));
     % % Manually determine region to keep; enter the numbers here.
     % xmin = 450; 
     % xmax = size(stack,2);
     % ymin = 1;
     % ymax = size(stack,1);
     % zmin = 1;
     % zmax = size(stack,3);
     % stack = stack(ymin:ymax, xmin:xmax, zmin:zmax);
     % fprintf('New x, y, z sizes: %d (x), %d (y), %d(z).\n', ...
     %     size(stack,2), size(stack,1), size(stack,3));
     
     % Determine the level to use to create the binary image 
     cd (startpath); %path to the folder that holds all the .tif stacks
     table = readtable("Timeseries-Intensities.txt");
     table_sub = head(table,10);
     level = mean(table_sub.threshold);
     mean_level = mean(table_sub.meanintensity);
     
     % Create stack_xy mat objects a
     scale_xy = 0.1625; % microns/px in xy
     stack_xy = sum(stack - level,3); % sum over all z slices, minus background
     stack_xy_mean = sum(stack - mean_level,3); % sum over all z slices, minus mean intensity
     cd (startpath)
     cd ./surfaceplot_stacks_levelsubtract
     file=("surfaceplot_stack-"+t+".mat");
     save(file, 'stack_xy');
     cd ../
     cd ./surfaceplot_stacks_meansubtract
     file=("surfaceplot_stack-"+t+".mat");
     save(file, 'stack_xy_mean');   
end