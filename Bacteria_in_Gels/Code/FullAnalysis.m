% This script combines all other scripts contained within this subsection of the
% repository to perform a full analysis of the data without user intervention
% required other than the intial path input. For a full description of each script,
% see each script or the subrepository README.

%=========================================================================%
% Patrick Horve + Raghu Parthasarathy - Fall 2021
%=========================================================================%

%% 1. Where are we and some setup
clear
prompt = {'\fontsize{15} Please enter absolute path to parent directory (There should be a folder in this parent directory named "Fish1"):'};
opts.Interpreter = 'tex';
Title = 'Attention!';
defaultans = {''};
userpath = inputdlg(prompt,Title,[1 75], defaultans, opts);
startpath = string(userpath);
cd (startpath); %path to the folder that holds all the .tif stacks
% How many timepoints are there in this dataset?
% go to our folder with all the timepoints
fish='/Fish1';
cd './Fish1'
% Counts the files in that folder
all_files = dir;
all_dir = all_files([all_files(:).isdir]);
timepoints = numel(all_dir)-2;

%% Script 1: THRESHOLDING
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

%% Script 2: STACK ANALYSIS
% Determine the level to use to create the binary image
cd (startpath); %path to the folder that holds all the .tif stacks
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

%% Script 3: SURFACEPLOT PREP
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

%% Script 4: SURFACE PLOTS
cd (startpath); %path to the folder that holds all the .tif stacks
mkdir("surfaceplots_threshold")
mkdir("IntensityXPosition_threshold")
mkdir("surfaceplots_mean")
mkdir("IntensityXPosition_mean")

% Level subtracted analysis
% 5. Start looping through the timepoints
for t = 1:timepoints
    cd surfaceplot_stacks_levelsubtract
    s = load("surfaceplot_stack-"+t+".mat");
    stack_xy = s.stack_xy;
    % Make the figure
    fig1 = figure; surf(stack_xy); shading interp
    caxis([-1000 10000]) % for example, to adjust it
    zlim([-1000 10000])
    view([-39.3 58.2412])
    xlabel('x, \mum')
    ylabel('y, \mum')
    title(sprintf('%.1f hours', t/6))
    colorbar


    stack_y = sum(stack_xy,2);
    fig2 = figure; plot(scale_xy*(1:length(stack_y)), stack_y)
    xlabel('y position, microns')
    ylabel('Intensity (summed)')
    cd ../
    cd surfaceplots_threshold
    % Save the fgiure
    saveas(fig1, ("surfaceplot-"+t+".png"))
    close(fig1)
    cd ../
    cd IntensityXPosition_threshold
    saveas(fig2, ("IntensitybyPosition-"+t+".png"))
    close(fig2)
    cd ../
    plot(scale_xy*(1:length(stack_y)), stack_y, '.'); hold on
end
hold off

% Mean subtracted analysis  figures
for t = 1:timepoints
    cd surfaceplot_stacks_meansubtract
    s = load("surfaceplot_stack-"+t+".mat");
    stack_xy = s.stack_xy_mean;
    % Make the figure
    fig1 = figure; surf(scale_xy*(1:size(stack_xy,2)), scale_xy*(1:size(stack_xy,1)), stack_xy); shading interp
    caxis([-1000 10000]) % for example, to adjust it
    zlim([-1000 10000])
    view([-39.3 58.2412])
    xlabel('x, \mum')
    ylabel('y, \mum')
    title(sprintf('%.1f hours', t/6))
    colorbar

    stack_y = sum(stack_xy,2);
    fig2 = figure; plot(scale_xy*(1:length(stack_y)), stack_y)
    xlabel('y position, microns')
    ylabel('Intensity (summed)')
    cd ../
    cd surfaceplots_mean
    % Save the fgiure
    saveas(fig1, ("surfaceplot-"+t+".png"))
    close(fig1)
    cd ../
    cd IntensityXPosition_mean
    saveas(fig2, ("IntensitybyPosition-"+t+".png"))
    close(fig2)
    cd ../
    plot(scale_xy*(1:length(stack_y)), stack_y, '.'); hold on
end
hold off
