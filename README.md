# Imaris_Prep
The ```Imaris_Prep.sh``` script takes output from a custom built light sheet microscope and expects the following directory architecture:

```
├──Parent Folder

    ├── Imaris_prep.sh           # Script provided in this repository

    ├── Fish1                    # Directory tree that contains the data, as output from the light sheet microscope

        ├── Timepoint?           # All timepoints from the lightsheet microscope should output in a separate folder (e.g. Timepoint1, Timepoint2, etc...)

            ├──Pos1

                ├──zStack

                    ├──GFP

                        ├──Default

                            ├──*.tif  # Individual .tif files with the images acquired by the light sheet microscope. The expected format of this file is as follows: img_channel000_position000_time000000000_z006.tif

```
**Current Known Issues**
1. The script will display an error saying that it is not able to find the last slice in each of the timpoints given. This will hopefully be fixed in a future version but does not significantly impact the performance of the script and I was too lazy to fix it right now :)

The ```Tif_convert.sh``` script is used to convert tif files to png files and moves all slices to a separate directory, inside of the main parent directory. 
