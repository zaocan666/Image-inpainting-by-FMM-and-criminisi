% 处理图片1
close all;clear;

addpath(genpath('FFM_inpaint'));
addpath(genpath('get_mask'));

I1 = imread('img1.JPG');
I1 = imresize(I1, 0.4); %为了提高运算速度，缩小图片
I1_gray = rgb2gray(I1);
line1_mask = get_mask_1(I1_gray, floor(509*size(I1,1)/719));

new_gray=I1_gray;
new_gray(line1_mask>0)=255;
%imshow(new_gray);

result_img = inpaint_FMM( I1, uint8(line1_mask/255), 3 );
figure;imshow(result_img);