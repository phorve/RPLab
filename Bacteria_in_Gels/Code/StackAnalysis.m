% This script will read in multiple .tif files output from a
% custom lightsheet flourescence microscope and quantify the total
% flourescence at each time point through the following steps 
    % 1. Applying the threshold: "imbinarize" returns a binary image
    % 2. Perform stats on the binarized images 

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

% Determine the level to use to create the binary image 
table = readtable("Timeseries-Intensities.txt");
table_sub = head(table,10);
level = mean(table_sub.threshold);
    
% Make our object directories
mkdir Matlab-Objects
mkdir imagepairs
mkdir Area-Histograms

% Prep to save off the files that we want 
filename="data_output";
extension=".mat";
p = ".png"; 
th = "threshold"; 
his = "histogram-";
a = "area";

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
     D = numel(all_tiff); % how many total tif files do we have in this  time point?
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
     
     % Create the binary image
     fprintf('Creating the 3D binary image for timepoint %d\n', t);
     bw_stack = stack > level;  % make our 3D binary image
     
     % Perform morphological closing (Raghu figured out it is actually faster to do this in a loop than to run it all in the stack, weird!)
     % Closing slice by slice, mainly for speed
     closing_radius = 2; % Use a small radius
     ste = strel('disk', closing_radius); % for Morphological closing. (slice by slice)
     fprintf("Performing morphological closing with a radius of %d.\n"+closing_radius);
     for j=1:size(bw_stack,3)
        bw_stack(:,:,j) = imclose(bw_stack(:,:,j), ste);
     end
     minPixels = 50; % minimum number of pixels (3D) to include after morphological closing
     fprintf("Discarding objects with fewer than %d pixels (3D).\n", minPixels);
     bw_stack = bwareaopen(bw_stack, minPixels); % discard regions with fewer than this number of pixels
     
     % Find connected regions, get statistics note that intensity is threshold-level-subtracted
     disp("Determining statistics on our 3D binary image stack for timepoint "+t);
     stats = regionprops3(bw_stack, stack, 'Volume', 'MaxIntensity', 'MeanIntensity', 'MinIntensity', 'WeightedCentroid');
     % Save our mast files for this timepoint 
     cd (startpath)
     cd ./Matlab-Objects
     file=(filename+t+extension);
     save(file, 'stats', '-v7.3');
     cd ../
     Nregions = size(stats,1);
     fprintf('%d objects were detected in this stack from timepoint %d.\n', Nregions, t)
     % Intensity and volume plots, and overall statistics
     % histogram of region intensity values (above threshold level)
     meanIntensity = stats.MeanIntensity;
     volume = stats.Volume;
     sumVolume = sum(volume);
     fprintf('Total segmented volume: %.4e pixels\n', sumVolume);
     
     % Total above-threshold intensity.
     % Note that we need to sum meanIntensity.*volume, because meanIntensity=alone is just the average pixel intensity in a region; a region of 100x as many pixels has 100x the total intensity!sumRegionIntensity = sum(meanIntensity.*volume);
     fprintf('Total intensity: %.4e\n', sumRegionIntensity);
     
     % NOTE: sumVolume and sumRegionIntensity (in addition to the whole stats array) are the important things to save for each time point.
     his_file=(his+a+t+p);
     fig1 = histogram(stats.Volume);
     xlim([0 90000])% probably need to change these for every dataset or just leave them extremely large to be able to work for both the control and treatment datasets 
     ylim([0 200])% probably need to change these for every dataset or just leave them extremely large to be able to work for both the control and treatment datasets 
     cd Area-Histograms
     saveas(fig1, his_file);
     cd ../
     % save off the original image and the binary image from a single slice of this timpoint 
     cd imagepairs
     fusedpair = imfuse(stack(:, :, 70), bw_stack(:, :, 70), 'montage');
     fused = ("imagepair"+t+".png");
     imwrite(fusedpair, fused);
     cd ../
     disp("======================================================")
 end