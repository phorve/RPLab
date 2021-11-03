#!/bin/bash
num=1
cd ./Fish1
times=$(ls -l | grep -c ^d)
echo "There are ""$times"" time points."
cd ../
mkdir ./Imaris_temp
mkdir ./Imaris_to_convert
for i in $(seq 1 $times)
do
  echo "This is timepoint ""$i"
  mv ./Fish1/Timepoint"$i"/Pos1/zStack/GFP/Default/*.tif ./Imaris_temp
  cd ./Imaris_temp
  slices=$(ls -1q img* | wc -l)
  cd ../
  echo "There are""$slices"" slices."
  for f in $(seq -f "%03g" 0 $slices)
  do
    echo "This is slice ""$f"
    mv ./Imaris_temp/img_channel000_position000_time000000000_z"$f".tif ./Imaris_temp/img_channel000_position000_time"$i"_z"$f".tif
    mv ./Imaris_temp/img_channel000_position000_time"$i"_z"$f".tif ./Imaris_to_convert
    echo "Finished moving and renaming slice #""$f"
  done
done
rmdir ./Imaris_temp
