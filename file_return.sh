#!/bin/bash
# Go into our Imaris directory
cd ./Imaris_to_convert

# Find all of the files that are in this folder and make a list of them
printf '%s\n' * | sed -e 's/\.tif$//' > ../files.txt

# Repositioning
cd ../

# find just the timpoints that are included in the files in the Imaris directory
IFS=$'\n'
set -f
file=./files.txt
for i in $(cat < "$file"); do
  echo "$i" | cut -d'_' -f 4 >> times.txt
done

# find just the slices that are included in the files in the Imaris directory
IFS=$'\n'
set -f
file=./files.txt
for i in $(cat < "$file"); do
  echo "$i" | cut -d'_' -f 5 >> slices.txt
done


# Find just the unique timepoints and slices from those files
sort -u ./times.txt > uniques.txt
sed 's/time/Timepoint/g' uniques.txt > updateduniques.txt

sort -u ./slices.txt > z.txt
# Move the files back to where they originally were
cd ./Imaris_to_convert

  zslice=$(cat ../z.txt)
  VAR1=$(cat ../updateduniques.txt)
  VAR2=$(cat ../uniques.txt)

  fun()
  {
      set $VAR2
      for i in $VAR1; do
          mv img_channel000_position000_"$1"_"$z".tif ../Fish1/"$i"/Pos1/zStack/GFP/Default
          mv ../Fish1/"$i"/Pos1/zStack/GFP/Default/img_channel000_position000_"$1"_"$z".tif ../Fish1/"$i"/Pos1/zStack/GFP/Default/img_channel000_position000_time000000000_"$z".tif
          echo "Finished moving and renaming slice #""$z"" from timepoint ""$i ""back to its original folder and name."
          shift
        done
      }
for z in $zslice; do
      fun
  done

# Move back to the main directory and delete all of our intermediate files that we no longer need
cd ../
rm files.txt | rmdir Imaris_to_convert | rm slices.txt | rm times.txt | rm uniques.txt | rm updateduniques.txt | rm z.txt
