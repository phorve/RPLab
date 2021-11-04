#!/bin/bash
# Note: This is a really slow running program and it is possible that some optimization could be done in the future. However, for now it would be best to run this when there is overnight. Each conversion from .tif to .png takes just over a second which can quickly add up when converting thousands of files!
cd ./Fish1
# Find all of our time points
times=$(ls -l | grep -c ^d)
# Read out how many time points there are
echo "There are ""$times"" time points."
# Make the parent directory for all of the converted png files
mkdir ../../../../../../Converted_PNGs
# 1st loop: all the timepoints
for i in $(seq 1 $times)
do
  # go to the timepoint that we are on
  cd ./Timepoint"$i"/Pos1/zStack/GFP/Default
  echo "This is timepoint ""$i"
  # Find all of the slices in that timepoint
  slices=$(ls -1q img* | wc -l)
  echo "There are""$slices"" slices."
  # Loop 2: convert all the slices to .png files
  for f in $(seq -f "%03g" 0 $slices)
  do
    echo "Starting slice ""$f"" from timepoint ""$i"
    convert -quiet ./img_channel000_position000_time000000000_z"$f".tif ./img_channel000_position000_time000000000_z"$f".png
    echo "Finished converting slice ""$f"" from timepoint ""$i"
  done
  # Make the specific directory for this time point
  mkdir ../../../../../../Converted_PNGs/Timepoint"$i"
  # Move all the converted .png files to that new directory
  mv *.png ../../../../../../Converted_PNGs/Timepoint"$i"
  echo "Finished moving all PNGs from timepoint ""$i"" to converted PNG folder"
done
