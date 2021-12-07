The script contained within this folder are used  for the identification and quantification of bacteria in an agar matrix as visualized with a light sheet microscope. There are 5 scripts further described below:

## Script1-Thresholding.m
This script reads in multiple .tif files output from a custom lightsheet flourescence microscope and outputs a table of the calculated thresholds from each time point

## Script2-StackAnalysis.m
This script will read in multiple .tif files output from a custom lightsheet flourescence microscope and quantify the total flourescence at each time point through the following steps
    1. Applying the threshold: "imbinarize" returns a binary image
    2. Perform stats on the binarized images
    3. Output tables for visualizations later on

## Script3-Surfaceplot_Prep.m
This script reads in multiple .tif files output from a custom lightsheet flourescence microscope and creates image stacks then calculates the sum of all slices in the Z direction to in preparation to create surface plots.

## Script4-Surfaceplots.m
This script reads in multiple .mat files used to create surfaceplots over time.

## Script5-Visualization.m
This script reads in data created from the four previous scripts in order to visualize the total number of objects visible over time, the total flourescence over time, and the objected-adjusted flourescence over time. *NOTE: This script is not generalized liek the others and wil need to be edited before use*
