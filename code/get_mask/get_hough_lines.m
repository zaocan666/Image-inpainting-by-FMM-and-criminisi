function [lines] = get_hough_lines(BW, line_length)
% hough变换提取图片中的直线
% 部分摘抄自：https://blog.csdn.net/yufeilongyuan/article/details/90443933

%直线检测
[H, theta , rho] = hough (BW);
%绘制霍夫空间
% figure;
% imshow(imadjust(mat2gray(H)),[],'XData',theta,'YData',rho,...
%         'InitialMagnification','fit');
% xlabel('\theta (degrees)'), ylabel('\rho');
% axis on, axis normal, hold on;
% colormap(hot); 
% title('霍夫空间')

P = houghpeaks(H,36);%,'threshold',0.2*max(H(:)));
lines = houghlines(BW,theta,rho,P,'FillGap',10,'MinLength',line_length);
%可视化
% figure;
% imshow(BW) ,hold on
% count = 1;
% points = zeros(2,2);
% for k = 1:length(lines)
%    points(count,1) = lines(k).point1(1);
%    points(count,2) = lines(k).point1(2);
%    count =count +1;
%    points(count,1) = lines(k).point2(1);
%    points(count,2) = lines(k).point2(2);
%    count =count +1;
%    xy = [lines(k).point1; lines(k).point2];
%    plot(xy(:,1),xy(:,2),'LineWidth',2,'Color','green');
%    % Plot beginnings and ends of lines
%    plot(xy(1,1),xy(1,2),'x','LineWidth',2,'Color','yellow');
%    plot(xy(2,1),xy(2,2),'x','LineWidth',2,'Color','red');
% end
% title('直线检测');

end