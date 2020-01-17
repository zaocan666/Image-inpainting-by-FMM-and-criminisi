function [new_lines] = lines_integrate(lines, angle_threhold, dis_threhold)
% 对hough变换检测到的直线做进一步处理
% 将lines中重复的直线去掉，并化成角度距离型

lines_kb=struct('k',0,'b',0, 'm', 0, 'dis', 0);
count=1;
for i=1:length(lines)
    p1=lines(i).point1;
    p2=lines(i).point2;
    
    if p1(2)~=p2(2)
        lines_kb(count).k=(p1(1)-p2(1))/(p1(2)-p2(2));
    else
        lines_kb(count).k=tan(abs(lines(i).theta*pi/180));
    end
    lines_kb(count).b=p1(1)-lines_kb(count).k*p1(2);
    lines_kb(count).dis=sqrt((p1(1)-p2(1))^2+(p1(2)-p2(2))^2);
    count=count+1;
end

[~, index] = sort([lines_kb.dis]);
lines_kb=lines_kb(index);%按两点距离排序
lines=lines(index);

%去掉重复直线，判断标准是两直线角度差以及距离
new_lines=struct('k',0,'b',0, 'm', 0, 'dis', 0);
count=1;
for i=1:length(lines_kb)
    exist_flag=false;
    for j=i+1:length(lines_kb)
        angle_dis=abs(atan(lines_kb(i).k)-atan(lines_kb(j).k))*180/pi;
        line_dis=abs(lines_kb(i).b-lines_kb(j).b)/sqrt(1+(lines_kb(i).k)^2);
        if line_point_dis(lines(i), lines(j))<5
            exist_flag=true;
            break;
        end
        if angle_dis<angle_threhold && line_dis<dis_threhold
            exist_flag=true;
            break;
        end
    end
    
    if exist_flag ~= true
        new_lines(count)=lines_kb(i);
        m = (1-lines_kb(i).b)/lines_kb(i).k;
        new_lines(count).m=m; %横坐标截距
        count = count+1;
    end
end

[~, index] = sort([new_lines.m]);
new_lines=new_lines(index);%将直线按从上都下的顺序排列

function [dis] = line_point_dis(line1, line2)
 dis1=sqrt((line1.point1(1)-line2.point1(1))^2+(line1.point1(2)-line2.point1(2))^2);
 dis2=sqrt((line1.point1(1)-line2.point2(1))^2+(line1.point1(2)-line2.point2(2))^2);
 dis3=sqrt((line1.point2(1)-line2.point1(1))^2+(line1.point2(2)-line2.point1(2))^2);
 dis4=sqrt((line1.point2(1)-line2.point2(1))^2+(line1.point2(2)-line2.point2(2))^2);
 dis = min([dis1 dis2 dis3 dis4]);
end

end