% This script reads in multiple .tif files output from a
% custom lightsheet flourescence microscope and outputs a table of the
% calculated thresholds from each time point

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

% Initial Setup and prep for the rest of the script
startpath = string(userpath);
cd (startpath); %path to the folder that holds all the .tif stacks

% Count the number of timepoints that are present in this image acquisition
% go to our folder with all the timepoints
fish='/Fish1';
cd './Fish1'
% Counts the files in that folder
all_files = dir;
all_dir = all_files([all_files(:).isdir]);
timepoints = numel(all_dir)-2;

% Set the thresholds for this dataset
minPixels = 50; % minimum number of pixels to include after morphological closing
pixels=num2str(minPixels);

% Start looping through the timepoints
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
    % Cropping (manual) - only use this if you want to crop out part of the image
%     fprintf('Original x, y, z sizes: %d (x), %d (y), %d(z).\n', ...
%         size(stack,2), size(stack,1), size(stack,3));
%     % Manually set the region to keep; enter the numbers here under xmin, ymin, and zmin arguments.
%     xmin = 450;
%     xmax = size(stack,2);
%     ymin = 1;
%     ymax = size(stack,1);
%     zmin = 1;
%     zmax = size(stack,3);
%     stack = stack(ymin:ymax, xmin:xmax, zmin:zmax);
%     fprintf('New x, y, z sizes: %d (x), %d (y), %d(z).\n', ...
%         size(stack,2), size(stack,1), size(stack,3));
    % Analysis for the current timepoint
    % Calculate statistics on a subset of pixels, faster than using the wholearray.
    disp("Determining the level to apply to the full stack");
    Npixels = numel(stack); % total number of pixels
    sampleFraction = 1/1000; % fraction of pixels to sample, for mean and std. dev.
    subSampleIdx = floor(linspace(1, Npixels, round(Npixels*sampleFraction)));
    meanIntensity = mean(stack(subSampleIdx), 'all');
    stdevIntensity = std(double(stack(subSampleIdx)),[], 'all');
    fprintf('Median and std. dev. (subsampled): %.1f, %.1f\n', meanIntensity, stdevIntensity);

% Threshold (z)
    z = 4; % threshold = median + z standard deviations
    level = meanIntensity + z*stdevIntensity;  % threshold level, not in [0,1]

% Save the thresholds for each timepoint
cd ../
if t==1
    output.timepoint = t;
    output.threshold = level;
    output.meanintensity = meanIntensity;
    output.stdevIntensity = stdevIntensity;
    output.z = z;
else
    tmp_table = table;
    tmp_table.timepoint = t;
    tmp_table.threshold = level;
    tmp_table.meanintensity = meanIntensity;
    tmp_table.stdevIntensity = stdevIntensity;
    tmp_table.z = z;
    output = [output ; tmp_table];
end
end
% Save our threshold values to a table to access later on
cd (startpath); %path to the folder that holds all the .tif stacks
writetable(output, "Timeseries-Intensities.txt")
