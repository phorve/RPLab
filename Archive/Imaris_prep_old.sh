#!/bin/bash
# Set the variables that we will use as messages later on in the processing
var1="This is timepoint "
var2="Finished moving slice #"

# Make the temporary directory that we will move the files to before changing the names
mkdir /Volumes/Data/Parthasarathy/27Oct2021_Pseudomonas/lmaris_temp

# Make the final directory that we will move the updated files to
mkdir /Volumes/Data/Parthasarathy/27Oct2021_Pseudomonas/lmaris_to_convert
# Loop 1: Cycle through all of the time points
for i in {1..84}
do
  # go to the folder for the timepoint that we are currently converting
  cd /Volumes/Data/Parthasarathy/27Oct2021_Pseudomonas/Fish1/Timepoint"$i"
  # display a message so that we can track the progress of the commands
  echo "$var1""$i"
  # move the files into the temporary folder
  mv ./Pos1/zStack/GFP/Default/*.tif /Volumes/Data/Parthasarathy/27Oct2021_Pseudomonas/lmaris_temp

  # Loop 2: cycle through each of the Z positions
  for f in $(seq -f "%03g" 1 313)
  do
    # go into the temporary folder where each of the files were moved into for that time point
    cd /Volumes/Data/Parthasarathy/27Oct2021_Pseudomonas/lmaris_temp
    # rename the files so that there is consistent Z-stack numbering and consistent timepoint numbering
    mv ./img_channel000_position000_time000000000_z"$f".tif ./img_channel000_position000_time"$i"_z"$f".tif
    # Display a message so that we can track the progress of the commands
    echo "$var2""$f"
    # copy the file with the new name to the original folder
    cp ./img_channel000_position000_time"$i"_z"$f".tif /Volumes/Data/Parthasarathy/27Oct2021_Pseudomonas/Fish1/Timepoint"$i"/Pos1/zStack/GFP/Default/img_channel000_position000_time"$i"_z"$f".tif
    # convert the original .tif file to a .png file to decrease the overall size
    convert /Volumes/Data/Parthasarathy/27Oct2021_Pseudomonas/Fish1/Timepoint"$i"/Pos1/zStack/GFP/Default/img_channel000_position000_time"$i"_z"$f".tif /Volumes/Data/Parthasarathy/27Oct2021_Pseudomonas/Fish1/Timepoint"$i"/Pos1/zStack/GFP/Default/img_channel000_position000_time"$i"_z"$f".png
    # delete the .tif file since we now have a .png file
    rm /Volumes/Data/Parthasarathy/27Oct2021_Pseudomonas/Fish1/Timepoint"$i"/Pos1/zStack/GFP/Default/img_channel000_position000_time"$i"_z"$f".tif
    # Display a message so that we can track the progress of the commands
    echo "Finished copying and converting slice ""$f"" from timepoint ""$i" "to a .png file in the original folder"
  done
  # Move all of the files from this iteration to the final folder that we will use when converting to a Imaris-compatible file
  mv /Volumes/Data/Parthasarathy/27Oct2021_Pseudomonas/lmaris_temp/*.tif /Volumes/Data/Parthasarathy/27Oct2021_Pseudomonas/lmaris_to_convert
done
# Once all of the files have been cycled through and moved to the final folder, we can delete the temporary folder
rmdir /Volumes/Data/Parthasarathy/27Oct2021_Pseudomonas/lmaris_temp
