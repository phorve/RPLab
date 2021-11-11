# RPLab

This repository holds all work and code relating to work done in the Parthasarathy lab ([@rpLab](https://github.com/rplab)) at the University of Oregon. To date, this holds code and documentation for two major purposes:
1. Bacteria_in_Gels
2. Imaris

=======================================================================================================================

## Bacteria_in_Gels
Documentation to come.

=======================================================================================================================

## Imaris_Prep
The ```Imaris_Prep.sh``` script takes output from a custom built light sheet microscope, renames the output files, and moves all files into a single folder so that they can be read by ```ImarisFileConverter```. To run this script, use the command ```bash Imaris_prep.sh```. This script expects the following directory architecture:

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
### file_return
The ```file_return.sh``` script is used to move the renamed files (executed through ```Imaris_Prep.sh```) back to their individual directories and their original file names (even though they kind of suck). In essence, this script undoes everything that was performed using ```Imaris_Prep.sh```. To run this script, use the command ```bash file_return.sh```.  

### Tif_convert
The ```Tif_convert.sh``` script is used to convert tif files to png files and moves all slices to a separate directory, inside of the main parent directory. This script expects the same directory architecture as described up above. To run this script, use the command ```bash Tif_convert.sh```.  

**Current Known Issues**
1. ```Imaris_Prep.sh``` display an error saying that it is not able to find the last slice in each of the timpoints given. This will hopefully be fixed in a future version but does not significantly impact the performance of the script and I was too lazy to fix it right now :)
