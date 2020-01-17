function [thick_mask, thin_mask] = get_mask_2(I_gray, black_area)
%检测图片二中栏杆的位置，返回两个mask，thick_mask是宽栏杆的mask，thin_mask是扁栏杆的mask

BW=imbinarize(I_gray,0.15); %二值化
% figure;
BW=((1-BW).*255);
BW(black_area:end, :)=0; %去除下面的干扰部分
% imshow(BW);hold on;

%检测宽栏杆
%找到宽栏杆内部的四个点
i_delta = black_area/4;
i_points = floor(black_area/8):i_delta:floor(black_area*7/8);
j_points = zeros(length(i_points));
count=1;
neibor_len=floor(30*size(BW,1)/1210);
for i=i_points
    j_neibor = zeros([1 size(BW,2)]);
    for j=1:size(BW,2)
       i_delta=min(min(neibor_len, i-1), size(BW,1)-i);
       j_delta=min(min(neibor_len, j-1), size(BW,2)-j);
       neibor_area = BW(floor(i-i_delta):floor(i+i_delta), floor(j-j_delta):floor(j+j_delta));
       j_neibor(j)=sum(sum(neibor_area>0)); %i j领域中白点数量
    end
    
    [~,j_point] = max(j_neibor);
%     plot(j_point, i_points(count),'x','LineWidth',2,'Color','red');
    j_points(count)=j_point;
    count=count+1;
end

%从宽栏杆内部四个点分别向左向右出发，找到宽栏杆共八个边界点
count=1;
for k=1:length(i_points)
   i_p = i_points(k);
   j_p = j_points(k);
   j_left=j_p;j_right=j_p;
   for j_search = j_p:-1:1 %找到宽栏杆的左边界点
       if BW(floor(i_p), floor(j_search))==0
           j_left=j_search;
           break;
       end
   end
   
   for j_search = j_p:1:size(BW,2) %找到宽栏杆的右边界点
       if BW(floor(i_p), floor(j_search))==0
           j_right=j_search;
           break;
       end
   end
   
   j_contour_left(count) = j_left;
   j_contour_right(count) = j_right;
   count = count+1;
%    plot(j_left, i_p,'x','LineWidth',2,'Color','yellow');
%    plot(j_right, i_p,'x','LineWidth',2,'Color','yellow');
end

%利用边界点拟合出宽栏杆的左右边界线
thick_line_left =polyfit(i_points, j_contour_left, 1); %左直线的k和b
thick_line_right =polyfit(i_points, j_contour_right, 1);%右直线的k和b
point_1_1 = 1*thick_line_left(1)+thick_line_left(2);
point_1_2 = size(BW,1)*thick_line_left(1)+thick_line_left(2);
point_2_1 = 1*thick_line_right(1)+thick_line_right(2);
point_2_2 = size(BW,1)*thick_line_right(1)+thick_line_right(2);
% plot([point_1_1 point_1_2], [1 size(BW,1)],'LineWidth',2,'Color','green');
% plot([point_2_1 point_2_2], [1 size(BW,1)],'LineWidth',2,'Color','green');

%得到宽栏杆左边区域和右边区域，并去除宽栏杆
oneRow = 1:size(I_gray,2);
martix_row = repmat(oneRow, [size(I_gray,1) 1]);
oneCol = 1:size(I_gray,1);
martix_col = repmat(oneCol', [1 size(I_gray,2)]);
ikLeft_b = martix_col.*thick_line_left(1)+thick_line_left(2);
ikRight_b = martix_col.*thick_line_right(1)+thick_line_right(2);

mask_left_left = martix_row<ikLeft_b; %在宽栏杆左直线左边的点为1
mask_right_right = martix_row>ikRight_b; %在宽栏杆右直线右边的点为1

mask_middle = and((martix_row>ikLeft_b),(martix_row<ikRight_b)); %在左右直线中间的点为1
mask_middle2 = and((martix_row>ikLeft_b-3),(martix_row<ikRight_b+3)); %拓展边界

BW(mask_middle)=0;

thick_mask = mask_middle2*255;

SE=strel('disk',2,4);
BW_dil = imdilate(BW,SE);
% figure;imshow(BW_dil);

[lines] = get_hough_lines(BW_dil, 40); %直线检测找到直线

%将检测到的直线分成三部分：宽栏杆左边的横线，宽栏杆右边的横线，竖线
middle_line = (thick_line_left + thick_line_right)/2; 
left_lines = lines(1); %宽栏杆左边的横线
right_lines = lines(1); %宽栏杆右边的横线
up_lines = lines(1); %竖线
for line = lines
   point_mid=(line.point1+line.point2)/2;
   if abs(line.theta)<45
       up_lines(length(up_lines)+1)=line;
       continue;
   end
   if line.point1(2)<5 && line.point2(2)<5
       continue;
   end
   
   if point_mid(2)*middle_line(1)+middle_line(2)>point_mid(1) %左边直线
       left_lines(length(left_lines)+1)=line;
   else
       right_lines(length(right_lines)+1)=line;
   end
end

if length(left_lines)>1
    left_lines=left_lines(2:end); 
end
if length(right_lines)>1
    right_lines=right_lines(2:end); 
end
if length(up_lines)>1
    up_lines=up_lines(2:end); 
end

%将检测到的直线标准化，转化成k、b形式，补充漏掉的直线，并去掉多余的直线
[left_new_lines] = lines_integrate(left_lines, 10, 15);
left_new_lines = complete_lines(left_new_lines, 1, 1);
[right_new_lines] = lines_integrate(right_lines, 10, 10);
right_new_lines = complete_lines(right_new_lines, 11, 901*size(I_gray, 2)/1418);
[up_new_lines] = lines_integrate(up_lines, 10, 10);

% figure;
% imshow(I_gray); hold on;
% for i=1:length(up_new_lines)
%     line=up_new_lines(i);
%     p1=[0 -line.b/line.k];
%     p2=[size(I_gray,2) (size(I_gray,2)-line.b)/line.k];
%     plot([p1(1) p2(1)], [p1(2) p2(2)],'LineWidth',2,'Color','green');
% end

%利用直线位置得到mask
line_width=floor(4*size(I_gray,1)/1210);
[left_line_mask] = maskFromlines(I_gray, line_width, left_new_lines, black_area, 6, false);
left_line_mask = left_line_mask.*mask_left_left;

[right_line_mask] = maskFromlines(I_gray, line_width, right_new_lines, black_area, 13, false);
right_line_mask = right_line_mask.*mask_right_right;

[up_line_mask1] = maskFromlines(I_gray, line_width*1.7, up_new_lines(1), black_area, 8, true);
[up_line_mask2] = maskFromlines(I_gray, line_width, up_new_lines(2), black_area, 6, true);
up_line_mask=up_line_mask1+up_line_mask2;

%返回两个mask，thick_mask是宽栏杆的mask，thin_mask是扁栏杆的mask
thin_mask = right_line_mask+left_line_mask+up_line_mask;
thin_mask(thin_mask>1)=1;
thin_mask=thin_mask.*255;
thin_mask(floor(391*size(I_gray,1)/605):end, :) = 0;
I_gray_temp = I_gray;
I_gray_temp(thick_mask>0)=255;
% figure;imshow(I_gray_temp);

end

%根据直线间的距离补充漏掉的直线
function [lines]=complete_lines(lines, add_num, left_start_y)
delta_m = lines(2).m-lines(1).m;
i=2;
while true
    if i==length(lines)
        break;
    end
    if (lines(i+1).m-lines(i).m)>1.5*delta_m %中间缺一根线
        middle_m = lines(i).m+delta_m;
        middle_k = lines(i).k;
        middle_b = 1-middle_k*middle_m;
        lines(i+2:end+1)=lines(i+1:end);
        lines(i+1).m = middle_m;
        lines(i+1).k = middle_k;
        lines(i+1).b = middle_b;
    else
        delta_m = lines(i+1).m-lines(i).m;
    end
    i=i+1;
end

start_m = (left_start_y-lines(end).b)/lines(end).k;
for i=1:add_num
    start_m = start_m+delta_m; %最后新增一条横线
    middle_k = lines(end).k;
    middle_b = left_start_y-middle_k*start_m;
    count = length(lines)+1;
    lines(count).m = (1-middle_b)/middle_k;
    lines(count).k = middle_k;
    lines(count).b = middle_b;
end

end