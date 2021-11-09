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
% prompt = {'What is the path to the parent directory of the images you want to analyze? (The first directory inside this folder should be something along the lines of "Fish1."'};
% dlg_title = 'Path Input'; num_lines= 1;
% path = "/path/to/parent/directory"; % default answer
% answer  = inputdlg(prompt,dlg_title,path);
prompt = {'\fontsize{15} Please enter absolute path to parent directory (There should be a folder in this parent directory named "Fish1"):'}; 
opts.Interpreter = 'tex'; 
Title = 'Attention!'; 
defaultans = {''}; 
userpath = inputdlg(prompt,Title,[1 75], defaultans, opts);
startpath = string(userpath);
cd (startpath); %path to the folder that holds all the .tif stacks 
fish='/Fish1';
cd './Fish1'
all_files = dir;
all_dir = all_files([all_files(:).isdir]);
timepoints = numel(all_dir);

for t = 1:timepoints
    disp("This is timepoint #"+t);
    time=string(t);
    fileFolder = strcat(startpath,fish,"/Timepoint",time,"/Pos1/zStack/GFP/Default");
    filePattern = fullfile(fileFolder, '*.tif');
    all_tiff  = dir(filePattern);
    cd (fileFolder)
    first_image = imread(all_tiff(1).name);
    [W,H] = size(first_image);
    D = numel(all_tiff);
    stack = zeros(W,H,D);
    stack(:,:,1) = first_image;
    for i = 2:D
        img=imread(all_tiff(i).name);
        level = graythresh(img);
        BW = imbinarize(img,level);
        imshowpair(img,BW,'montage');
        pixelcount = nnz(BW > level);
        disp(pixelcount+" pixels above the auto-calculated threshold")
        stack(:,:,i) = img;
        disp(string(i*100.0/D) + "%"); % uncomment this line for seeing the reading progress
    end
% The app volumeViewer will handle the visualization
% volumeViewer(stack);
end