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
% Patrick made edits (with input and advice from Raghu) on 15 Nov 2021 
% Significant edits from Raghu on 19 Nov 2021 
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
% Make our object directories
mkdir Area-Histograms
mkdir Intensity-Histograms
mkdir Matlab-Objects
mkdir imagepairs
% Prep to save off the files that we want 
filename="data_output";
filename2="data_output2";
extension=".mat";
his = "histogram-"; 
p = ".png"; 
a = "area"; 
int = "intensity"; 
th = "threshold"; 
%=========================================================================%
%=========================================================================%
%% 3. Count the number of timepoints that are present in this image acquisition
% go to our folder with all the timepoints 
fish='/Fish1';
cd './Fish1'
% Counts the files in that folder 
all_files = dir;
all_dir = all_files([all_files(:).isdir]);
timepoints = numel(all_dir)-2;
%=========================================================================%
%=========================================================================%
%% 4. Set the thresholds for this dataset
ste = strel('disk', 2); % for Morphological closing.
ste_text="2";
minPixels = 50; % minimum number of pixels to include after morphological closing 
pixels=num2str(minPixels);
%=========================================================================%
%=========================================================================%
%% 5. Start looping through the timepoints
output = table;
%for t = 30:66 %Use this if you are using a series of timepoints that don't
% start at 1
for t = 1:timepoints 
    tic
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
 
    %% Cropping (manual)
fprintf('Original x, y, z sizes: %d (x), %d (y), %d(z).\n', ...
    size(stack,2), size(stack,1), size(stack,3));
% Manually determine region to keep; enter the numbers here.
xmin = 450; 
xmax = size(stack,2);
ymin = 1;
ymax = size(stack,1);
zmin = 1;
zmax = size(stack,3);
stack = stack(ymin:ymax, xmin:xmax, zmin:zmax);
fprintf('New x, y, z sizes: %d (x), %d (y), %d(z).\n', ...
    size(stack,2), size(stack,1), size(stack,3));
%% 6. Analysis for the current timepoint 
   % not the whole image stack
    % Calculate statistics on a subset of pixels, faster than using the whole
    % array.
    disp("Determining the level to apply to the full stack");
    Npixels = numel(stack); % total number of pixels
    sampleFraction = 1/1000; % fraction of pixels to sample, for mean and std. dev.
    subSampleIdx = floor(linspace(1, Npixels, round(Npixels*sampleFraction)));
    medianIntensity = median(stack(subSampleIdx), 'all');
    stdevIntensity = std(double(stack(subSampleIdx)),[], 'all');
    fprintf('Median and std. dev. (subsampled): %.1f, %.1f\n', medianIntensity, stdevIntensity);


%% Threshold (z)
    z = 4; % threshold = median + z standard deviations
    level = medianIntensity + z*stdevIntensity;  % threshold level, not in [0,1]
end
    
    
    
    
    
    %% SPLIT HERE 
    fprintf('Creating the 3D binary image for timepoint %d\n', t);
    bw_stack = stack > level;  % make our 3D binary image

   % Perform morphological closing (Raghu figured out it is actually faster
   % to do this in a loop than to run it all in the stack, weird!)
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

%% Find connected regions, get statistics
% note that intensity is threshold-level-subtracted
disp("Determining statistics on our 3D binary image stack for timepoint "+t);
stats = regionprops3(bw_stack, (stack - level), 'Centroid', ... % just use the stack, not stack-level
    'PrincipalAxisLength', 'Volume', 'VoxelIdxList', 'MaxIntensity', ...
    'MeanIntensity', 'MinIntensity', 'VoxelValues', 'WeightedCentroid');
disp("Saving our statistics to 'output_data.mat'");
   cd (startpath)
   cd ./Matlab-Objects
   file=(filename+t+extension);
   save(file, 'stats');
Nregions = size(stats,1);
fprintf('%d objects were detected in this stack from timepoint %d.\n', Nregions, t)
% takes about 20 seconds



rwiye origram to just get 


%% Intensity and volume plots, and overall statistics
% histogram of region intensity values (above threshold level)
meanIntensity = stats.MeanIntensity;
meanIntensity2 = mean(stats.MeanIntensity);
figure; histogram(meanIntensity,50)
xlabel('Mean Intensity')

volume = stats.Volume;
sumVolume = sum(volume);
fprintf('Total segmented volume: %.4e pixels\n', sumVolume);

% Total above-threshold intensity.
% Note that we need to sum meanIntensity.*volume, because meanIntensity
%   alone is just the average pixel intensity in a region; a region of 100x
%   as many pixels has 100x the total intensity!
sumRegionIntensity = sum(meanIntensity.*volume);
fprintf('Total intensity: %.4e\n', sumRegionIntensity);

% NOTE: sumVolume and sumRegionIntensity (in addition to the whole stats
% array) are the important things to save for each time point.

    cd ../
    if t==1 % Change to your first timepoint
        output.timepoint = t;
        output.intensity = meanIntensity2;
        output.sumVolume = sumVolume;
        output.threshold = level;
        his_file=(his+a+t+p);
        his_file2=(his+int+t+p);
        h = histogram(stats.Volume);
        cd Area-Histograms
        saveas(h, his_file)
        cd ../
        cd Intensity-Histograms
        h=figure; histogram(meanIntensity,50)
        saveas(h, his_file2)
        cd ../
        cd imagepairs
        fusedpair = imfuse(stack(:, :, 70), bw_stack(:, :, 70));
        fused = ("imagepair"+t+".png");
        imwrite(fusedpair, fused);
        cd ../
    else 
        tmp_table = table;
        tmp_table.timepoint = t;
        tmp_table.intensity = meanIntensity2;
        tmp_table.sumVolume = sumVolume;
        tmp_table.threshold = level;
        output = [output ; tmp_table]; 
        his_file=(his+a+t+p);
        his_file2=(his+int+t+p);
        h = histogram(stats.Volume);
        cd Area-Histograms
        saveas(h, his_file)
        cd ../
        h=figure; histogram(meanIntensity,50)
        cd Intensity-Histograms
        saveas(h, his_file2)
        cd ../
        cd imagepairs
        fusedpair = imfuse(stack(:, :, 70), bw_stack(:, :, 70), 'montage');
        fused = ("imagepair"+t+".png");
        imwrite(fusedpair, fused);
        cd ../
    end
    toc
    disp("======================================================")
end 
toc
%%
















% % 7. Save our final figures from all the loop data 
% Make a directory for our final figures 
% mkdir figures
% Go to that directory 
% cd figures
% Save our final data table as a .txt file 
% writetable(output)
% Save our intensity over time plot 
% figure1 = figure; plot(output.timepoint, output.intensity);
% top1=(int+p);
% saveas(figure1, top1);
% Save our threshold over time plot 
% figure2 = figure; plot(output.timepoint, output.threshold);
% top2=(th+p);
% saveas(figure2, top2);
% End of script 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
%    imshowpair(stack(:, :, 70), bw_stack(:, :, 70), 'montage');
%    Get all the stats on our stack image for analysis 
%    L = bwlabeln(bw_stack); 
%    disp( max(L(:))+" objects were detected in this stack from timepoint "+t)
%    disp("Determining statistics on our 3D binary image stack for timepoint "+t);
%    stats = regionprops3(bw_stack, (stack - level), 'Centroid', 'PrincipalAxisLength', 'Volume', 'VoxelIdxList', 'MaxIntensity', 'MeanIntensity', 'MinIntensity', 'VoxelValues', 'WeightedCentroid');
%    stats2 = stats;
%    stats2(stats2.MeanIntensity < 0.5*std(double(stack(:, :, slice_to_consider)), [], 'all'), :) = [];
%    disp("Saving our statistics to 'output_data.mat'");
%    cd (startpath)
%    cd ./Matlab-Objects
%    file=(filename+t+extension);
%    file2=(filename+t+"-try2"+extension);
%    disp("Saving the matrix")
%         save(file, 'stats');
%         save(file2, 'stats2');
%     FileData = load(file);
%     FileData.stats.AdjustedIntensity = FileData.stats.MeanIntensity - level; % This is not needed since we already subtracted out up above at line 100
%     Separate out the intensity of each slice from that time point 
%     intensity = FileData.stats{:,7};
%     What is the total intensity of that time point 
%     intensity = sum(intensity);
%     output_data = (intensity-level); % This is not needed since we already subtracted out up above at line 100
%     disp(output_data+" is the total intensity above the threshold for timepoint "+t)
%     cd ../
%     if t==1 % Change to your first timepoint
%         output.timepoint = t;
%         output.intensity = intensity;
%         output.threshold = level;
%         his_file=(his+a+t+p);
%         his_file2=(his+int+t+p);
%         h = histogram(FileData.stats.Volume);
%         cd Area-Histograms
%         saveas(h, his_file)
%         cd ../
%         h = histogram(FileData.stats.MeanIntensity);
%         cd Intensity-Histograms
%         saveas(h, his_file2)
%         cd ../
%     else 
%         tmp_table = table;
%         tmp_table.timepoint = t;
%         tmp_table.intensity = intensity;
%         tmp_table.threshold = level;
%         output = [output ; tmp_table]; 
%         his_file=(his+a+t+p);
%         his_file2=(his+int+t+p);
%         h = histogram(FileData.stats.Volume);
%         cd Area-Histograms
%         saveas(h, his_file)
%         cd ../
%         h = histogram(FileData.stats.MeanIntensity);
%         cd Intensity-Histograms
%         saveas(h, his_file2)
%         cd ../
%     end
%     disp("======================================================")
% end 
% % 7. Save our final figures from all the loop data 
% Make a directory for our final figures 
% mkdir figures
% Go to that directory 
% cd figures
% Save our final data table as a .txt file 
% writetable(output)
% Save our intensity over time plot 
% figure1 = figure; plot(output.timepoint, output.intensity);
% top1=(int+p);
% saveas(figure1, top1);
% Save our threshold over time plot 
% figure2 = figure; plot(output.timepoint, output.threshold);
% top2=(th+p);
% saveas(figure2, top2);
% End of script 
% 
% % 8. Quick plots that Raghu suggested 
% stack_y = mean(stack, [2, 3]);
% scale_xy = 0.1625; % um/px
% figure3 = figure; plot(scale_xy*(1:size(stack,1)), stack_y)
% xlabel('x, \mum')
% ylabel('intensity')
% saveas(figure3, "DimensionsAverage.png");
% 
% % 9. 
% prompt = {'\fontsize{15} Please enter absolute path to parent directory (There should be a folder in this parent directory named "Fish1"):'};
% opts.Interpreter = 'tex';
% Title = 'Attention!';
% defaultans = {''};
% userpath = inputdlg(prompt,Title,[1 75], defaultans, opts);
% =========================================================================%
% =========================================================================%
% startpath = string(userpath);
% cd (startpath); %path to the folder that holds all the .tif stacks
% fish='/Fish1';
% cd './Fish1'
% Counts the files in that folder 
% all_files = dir;
% all_dir = all_files([all_files(:).isdir]);
% timepoints = numel(all_dir);
% stack_y_t = zeros(2160, (timepoints-1));
% disp('hard-coded -- change!')
% for t = 1:(timepoints-1) 
%     disp("This is timepoint #"+t); % track the progress of the script
%     time=string(t); % make the timepoint something that we can use in a path
%     fileFolder = strcat(startpath,fish,"/Timepoint",time,"/Pos1/zStack/GFP/Default"); % where are all of our .tif files located?
%     filePattern = fullfile(fileFolder, '*.tif'); % the pattern of the files that we are interested in
%     all_tiff  = dir(filePattern); % make a list of all the .tif files for this timepoint
%     cd (fileFolder); % go that folder to actually start doing things with all of the .tif files
%     first_image = imread(all_tiff(1).name); % read in the first .tif image at this time point
%     [W,H] = size(first_image); % set the dimensions -- this could also be used to crop the images in the same location if needed
%     D = numel(all_tiff); % how many total tif files do we have in this  time point?
%     stack = zeros(W,H,D); % make our 3d stack object
%     stack(:,:,1) = first_image; % add our first image to the stack
%         for i = 2:D % cycle through all of the .tif files for this timepoint and make a 3d array with all of the .tif files at this timpoint
%         img=imread(all_tiff(i).name); % read in the next image
%         stack(:,:,i) = img; % add this image to the image stack
%         disp(string(i*100.0/D) + "% of the images from this timepoint added to the 3D array"); % for seeing the reading progress
%         end
%     stack_y_t(:,t) = mean(stack, [2, 3]);
% end
% figure; surf(stack_y_t); shading interp
% save("stack_y_t_control.mat", 'stack_y_t');
%  