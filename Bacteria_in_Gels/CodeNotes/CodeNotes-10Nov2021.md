# Bacteria in gels image analysis notes - 10 November 2021
Patrick’s code: TotalFlouro_ImageAnalysis.m (now Flourescence_over_time.m)

*Challenges: setting the level for thresholding*

1. Looking at, for example, Timepoint 29 in the 1Nov21 set of antibiotic-treated images, the min, max, median, and standard deviation of intensities are 16, 348, 120, and 8.7. Note that each stack has 2160*2560*302 = 1.7e9 pixels! Therefore, calculating median and std dev takes a while. Just looking at one slice gives almost identical results, and is of course much faster.

2. Automated level finding (Otsu’s method, using graythresh) returns zero. I’m puzzled by this – is it because it’s a 16-bit image? graythresh is supposed to work with uint16. Looking at its code, though, it converts all arrays to 8-bit! This is ridiculous.

3. I should rewrite graythresh.m ... I do this. Function graythresh_RP16bit.m , put on GitHub in \Image-Analysis-of-Particles-and-Membranes\MATLAB\Image Processing

4. The Otsu threshold, even if properly calculated, won’t help, though. The images are dominated by the background, with a roughly Gaussian distribution about the median, so Otsu’s method will simply return the median. Histogram of slice 186 of timepoint 29:

![ ](Bacteria_in_Gels/Images/10Nov2021-1.png)

5. The automated threshold value is 0.0018 x 65535 = 120  -- in the middle of the bell curve.

6. Let’s instead set a threshold that’s z standard deviations above the median. z = 3 will give lots of false positives (1/740 px for a Gaussian distribution), but most will be single pixels.

```level = median(im29_186(:)) + z*std(double(im29_186(:)));  % not in [0,1]
im29_186_bw = im29_186 > level;
```

7. For z = 3, here’s a subset of one slice:

![ ](Bacteria_in_Gels/Images/10Nov2021-2.png)

8. How slow will it be to do morphological closing and opening? Will worry about that later. After closure with a disk of radius 2:

```ste = strel('disk', 2)
im29_186_bw_mod = imclose(im29_186_bw, ste);
```

![ ](Bacteria_in_Gels/Images/10Nov2021-3.png)

9. Then ```bwareaopen``` to remove objects with less than 4 pixels:

```im29_186_bw_mod = bwareaopen(im29_186_bw_mod, 4);```

![ ](Bacteria_in_Gels/Images/10Nov2021-4.png)

10. Could save the number of pixels, the total intensity in these pixels, all regions, ...

11. For now, I write some code to just calculate the first two.

*To do:*
1. Also save median intensity, total intensity, of the images
2. Organize these measures into arrays.
3. ```regionprops``` – calculate region properties, including positions.
4. Median filtering? De-noising? Probably slow and unnecessary.
