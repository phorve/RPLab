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
% Edits made by Raghu on 10 November 2021
% Patrick and Raghu met on 11 November 2021 and discussed analysis
% Patrick made edits (with input and advice from Raghu) on 11 Nov 2021
%=========================================================================%
%=========================================================================%
%% 1. Prompt setup for working directory
tic
prompt = {'\fontsize{15} Please enter absolute path to parent directory (There should be a folder in this parent directory named "Fish1"):'};
opts.Interpreter = 'tex';
Title = 'Attention!';
defaultans = {''};
userpath = inputdlg(prompt,Title,[1 75], defaultans, opts);
%=========================================================================%
%=========================================================================%
%% 2. Initial Setup and prep for the rest of the script
startpath = string(userpath);
cd (startpath); %path to the folder that holds all the .tif stacks
fish='/Fish1';
cd './Fish1'
filename="data_output";
extension=".mat";
%=========================================================================%
%=========================================================================%
%% 3. Count the number of timepoints that are present in this image acquisition
all_files = dir;
all_dir = all_files([all_files(:).isdir]);
timepoints = numel(all_dir);
%=========================================================================%
%=========================================================================%
%% 4. Set the thresholds for this dataset
ste = strel('disk', 5); % for Morphological closing.
ste_text="5";
minPixels = 50; % minimum number of pixels to include after morphological closing 
pixels=num2str(minPixels);
%=========================================================================%
%=========================================================================%
%% 5. Start looping through the timepoints
output = table;
for t = 30:66
%for t = 1:timepoints % use this for the majority of scripts 
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
    for i = 2:D % cycle through all of the .tif files for this timepoint and make a 3d array with all of the .tif files at this timpoint
        img=imread(all_tiff(i).name); % read in the next image
        stack(:,:,i) = img; % add this image to the image stack
        disp(string(i*100.0/D) + "% of the images from this timepoint added to the 3D array"); % for seeing the reading progress
    end
   %% 6. Analysis for the current timepoint
   slice_to_consider = 100; % for speed, just use one slice for the level, 
   disp("Using slice #"+slice_to_consider+" to determine the level to use");
   % not the whole image stack
   z = 4; % threshold = median + z standard deviations
   disp("Determining the level to apply to the full stack");
   level = median(stack(:, :, slice_to_consider), 'all') + z*std(double(stack(:, :, slice_to_consider)), [], 'all');  % not in [0,1]
   disp("Creating the 3D binary image for timepoint "+t);
   bw_stack = stack > level;  % make our 3D binary image
   disp("Performing morphological closing with a value of "+ste_text);
   bw_stack = imclose(bw_stack, ste); % morphological closing
   disp("Discarding objects with fewer than "+pixels+" pixels");
   bw_stack = bwareaopen(bw_stack, minPixels); % discard things with fewer than this number of pixels
   % Get all the stats on our stack image for analysis 
   L = bwlabeln(bw_stack); 
   disp( max(L(:))+" objects were detected in this stack from timepoint "+t)
   disp("Determining statistics on our 3D binary image stack for timepoint "+t);
   stats = regionprops3(bw_stack, stack - level, 'Centroid', 'PrincipalAxisLength', 'Volume', 'VoxelIdxList', 'MaxIntensity', 'MeanIntensity', 'MinIntensity', 'VoxelValues', 'WeightedCentroid');
   disp("Saving our statistics to 'output_data.mat'");
   cd (startpath)
   file=(filename+t+extension);
   disp("Saving the matrix")
        save(file, 'stats');
    cd (startpath)    
    FileData = load(file);
    % Separate out the intensity of each slice from that time point 
    intensity = FileData.stats{:,1};
    % What is the total intensity of that time point 
    intensity = sum(intensity);
    output_data = (intensity-level);
    disp(output_data+"is the total intensity above the threshold for timepoint "+t)
    if t==1
        output.timepoint = t;
        output.intensity = output_data;
    else 
        tmp_table = table;
        tmp_table.timepoint = t;
        tmp_table.intensity = output_data;
        output = [output ; tmp_table]; 
    end
    disp("======================================================")
end 
toc