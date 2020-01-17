function [line_mask] = get_mask_1(I_gray, black_area)
%检测图片一中栏杆的位置

BW=imbinarize(I_gray,0.14); %二值化
%figure;
BW=((1-BW).*255);
BW(black_area:end, :)=0; %去除下面的干扰部分
%imshow(BW)

[lines] = get_hough_lines(BW, 100); %hough变换获取直线

%将检测到的直线标准化，转化成k、b形式，并去掉多余的直线
[new_lines] = lines_integrate(lines, 10, 30);

%利用相邻直线间的距离，补上遗漏的直线
delta_m = new_lines(2).m-new_lines(1).m;
for i=2:length(new_lines)
    if abs(new_lines(i+1).k)<5 %下一条线是竖线
        middle_m = new_lines(i).m+delta_m;
        middle_k = new_lines(i).k;
        middle_b = 1-middle_k*middle_m;
        count = length(new_lines)+1;
        new_lines(count).m = middle_m; %新增一条横线
        new_lines(count).k = middle_k;
        new_lines(count).b = middle_b;

        break;
    end
    
    if (new_lines(i+1).m-new_lines(i).m)>1.5*delta_m %中间缺一根线
        middle_m = (new_lines(i+1).m+new_lines(i).m)/2;
        middle_k = (new_lines(i+1).k+new_lines(i).k)/2;
        middle_b = 1-middle_k*middle_m;
        count = length(new_lines)+1;
        new_lines(count).m = middle_m;
        new_lines(count).k = middle_k;
        new_lines(count).b = middle_b;
    else
        delta_m = new_lines(i+1).m-new_lines(i).m;
    end
end

%figure;
%imshow(I_gray); hold on;
% for i=1:length(new_lines)
%     line=new_lines(i);
%     p1=[0 -line.b/line.k];
%     p2=[size(I_gray,2) (size(I_gray,2)-line.b)/line.k];
%     plot([p1(1) p2(1)], [p1(2) p2(2)],'LineWidth',2,'Color','green');
% end

%利用直线位置得到mask
line_width=floor(2*size(I_gray)/719);
[line_mask] = maskFromlines(I_gray, line_width, new_lines, black_area, 30, false);

%imshow(uint8(line_mask));