clear;close all;

addpath(genpath('FFM_inpaint'));
addpath(genpath('get_mask'));
addpath(genpath('criminisi_inpaint'));

%得到栏杆部分的mask
I2 = imread('img2.JPG');
I2 = imresize(I2, 0.2); %缩小图片
I2_gray = rgb2gray(I2);
[line2_thick_mask, line2_thin_mask] = get_mask_2(I2_gray, floor(716*size(I2,1)/1210));
mask2 = line2_thick_mask+line2_thin_mask;
mask2(mask2>0)=255;

%先用FFM算法进行修复
scale2=0.5;
I2_small = imresize(I2, scale2); %再次缩小图片，较少运算时间
mask_thick_small = imresize(line2_thick_mask, scale2); 
mask2_small = imresize(mask2, scale2);
result_ffm_img = inpaint_FMM( I2_small, uint8(mask2_small/255), 3 ); 

%用criminisi算法对宽栏杆部分进行修复
result_img = inpaint_criminisi(result_ffm_img, mask_thick_small>0, 3, 'fast');
imshow(uint8(result_img));
