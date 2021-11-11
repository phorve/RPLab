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
levelimg=imread(startpath+fish+"/Timepoint1/Pos1/zStack/GFP/Default/img_channel000_position000_time000000000_z200.tif");

slice_to_consider = 1; % for speed, just use one slice for the level, %PATRICK NOTE: Changed this to 1 since we are only loading in one slice right now, but we could use this to select just a single slice 
   % not the whole image stack
z = 3; % threshold = median + z standard deviations
level = median(levelimg(:, :, slice_to_consider), 'all') + ...
    z*std(double(levelimg(:, :, slice_to_consider)), [],  'all');  % not in [0,1]
testimage = levelimg(:, :, slice_to_consider) > level;

ste = strel('disk', 2); % for Morphological closing.
testimage = imclose(testimage, ste);
minPixels = 4;
testimage = bwareaopen(testimage, minPixels);

imshow(testimage);
imshowpair(levelimg(:, :, slice_to_consider), testimage, 'montage');

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

        total = sum(double(img(:))); % sum pixel intensity -- may not be necessary to make double, but in case we're close to saturating the 16-bit range
        
        disp(total+"  is the overall intensity of the pixels") % display the sum pixel intensity for tracking purposes 
        %level = graythresh(img); % replaced this thresholding with the thresholding step in section 3 
        %thresholding up above 
        
        BW = img > level; % binarize
        BW = imclose(BW, ste);
        minPixels = 4;
        BW = bwareaopen(BW, minPixels);
        
        imshowpair(img,BW,'montage'); % show the comparison between the two images 
        
        % pixelcount = nnz(BW > level); % count pixels above the threshold 
        pixelcount = sum(BW(:)); % count pixels above the threshold 
        intensityAboveThreshold = sum(double(img).*BW, 'all'); % total intensity in above-threshold pixels
        
        disp(pixelcount+" pixels above the auto-calculated threshold") % display how many pixels are above the threshold for tracking purposes 
        stack(:,:,i) = img; % add this image to the image stack 
        disp(string(i*100.0/D) + "%"); % for seeing the reading progress
        cd (startpath); % move back to
        filename = sprintf('data%04d.txt',t); % what is the filename for this time series? 
        save(filename, 'total'); % Save the data from this iteration of the loop 
        save(filename, 'total', '-append'); % apparantly you can't append until you already had a file... so make the file and then immediately append it 
        cd (fileFolder);
        disp("======================================================")
    end
end