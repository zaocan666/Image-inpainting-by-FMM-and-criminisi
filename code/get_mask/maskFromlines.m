function [line_mask] = maskFromlines(I_gray, line_width, new_lines, black_area, find_len, upLineFind)
%利用直线位置得到mask，在直线附近灰度值低的部分mask值为1，其他部分mask为0

line_mask=zeros(size(I_gray));
for i=1:length(new_lines)
    line = new_lines(i);
    if abs(line.k)==inf
        continue;
    end
    
    if abs(line.k)>5 %横线
        for p_j=1:size(I_gray,2) %直线上所有纵坐标
           p_i=(p_j - line.b)/line.k; %直线上对应的横坐标
           if p_i<1 || p_i>size(I_gray,1)
               continue;
           end
           
           if p_i>black_area
               min_i = p_i;
           else
               find_dis=find_len;
               if p_i-find_dis<1
                   find_dis=p_i-1;
               end
               if p_i+find_dis>size(I_gray,1)
                   find_dis=size(I_gray,1)-p_i;
               end
               [min_g, min_i] = min(I_gray(floor(p_i-find_dis):floor(p_i+find_dis), p_j)); %直线上该点同一列附近极小值点
               min_i = p_i-find_dis+min_i-1;
           end
           
           for mask_i=min_i-line_width:min_i+line_width %极小值点附近的黑点
              if mask_i<1 || mask_i>size(I_gray,1)
                continue;
              end
              line_mask(floor(mask_i), p_j)=255;
           end
        end
    else %竖线
        for p_i=1:size(I_gray,1) %直线上所有横坐标
           p_j=p_i*line.k+line.b; %直线上对应的纵坐标
           if p_j<1 || p_j>size(I_gray,2)
               continue;
           end
           
           if upLineFind==true
               find_dis=find_len;
               if p_j-find_dis<1
                   find_dis=p_j-1;
               end
               if p_j+find_dis>size(I_gray,2)
                   find_dis=size(I_gray,2)-p_j;
               end
               [min_g, min_j] = min(I_gray(p_i, floor(p_j-find_dis):floor(p_j+find_dis))); %直线上该点同一行附近极小值点
               min_j = p_j-find_dis+min_j-1;
           else
               min_j=p_j;
           end
           
           for mask_j=min_j-line_width-1:min_j+line_width+1 %极小值点附近的黑点
              if mask_j<1 || mask_j>size(I_gray,2)
                continue;
              end
              line_mask(p_i, floor(mask_j))=255;
           end
        end
    end
end

end