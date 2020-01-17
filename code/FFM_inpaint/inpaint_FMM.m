function [ image ] = inpaint_FMM( image, mask, radius )
%FMM算法的初始化和主循环

SE=strel('square',3);%矩形mask
F = imdilate(mask, SE); %mask膨胀
F(F>1)=1; %F=mask 并且mask中每个有值点的上下左右都为1

%求出标志矩阵F，待修补区域中的点值为2（内部点，未知点），待修补区域边界点值为1，已知像素区域的点值为0
F_temp = F;
F_temp(mask>0)=0;
F = F .* 2 - F_temp;

%距离矩阵T，表示一个点到待修补区域边缘的距离
T = (F == 2) .* 1e6;

%建立最小堆，存储边缘点，以其T值为value
[contour_x, countour_y] = find(F == 1);
heap = myMinheap(); 
h_temp = myMinheap();

for i=1:length(contour_x)
    point.x=contour_x(i);
    point.y=countour_y(i);
    
    heap.min_heap_insert(point, T(point.x,point.y));
    h_temp.min_heap_insert(point, T(point.x,point.y));
end
heap.min_heap_adjust();

[T]=compute_outside(T, F, h_temp, radius); %计算外围部分点的T

neibor_is = [];
neibor_js = []; %算好圆形领域中的点坐标，避免重复计算
for i=-radius:radius 
    i_height = floor(sqrt(radius.^2 - i.^2));
    for j=-i_height:i_height
        neibor_is(end+1) = i;
        neibor_js(end+1) = j;
    end
end

while heap.size~=0
    %取出T值最小的边缘点，即最佳边缘点
    [min_p,~]=heap.min_heap_popup();
    i = min_p.x;
    j = min_p.y;

    F(i, j) = 0; %变成外部点

    neighbors_i = [i+1, i-1, i, i];
    neighbors_j = [j, j, j+1, j-1];

    for p=1:length(neighbors_i)
       i_neib = neighbors_i(p);
       j_neib = neighbors_j(p);

       if i_neib<1 || i_neib>size(F,1) || j_neib<1 || j_neib>size(F,2)
         continue
       end

       %找到边缘点旁边的内部点
       if F(i_neib, j_neib) == 2 %内部点
           %计算内部点的T
           T(i_neib, j_neib) = min([solve_T(T, F, i_neib, j_neib+1, i_neib-1, j_neib),...
                            solve_T(T, F, i_neib, j_neib-1, i_neib-1, j_neib),...
                            solve_T(T, F, i_neib, j_neib+1, i_neib+1, j_neib),...
                            solve_T(T, F, i_neib, j_neib-1, i_neib+1, j_neib)]);

           point.x=i_neib;
           point.y=j_neib;
           heap.min_heap_insert(point, T(point.x,point.y));

           %插值计算该内部点的像素值
           pix_result = inpaint_p(image, T, F, neibor_is, neibor_js, i_neib, j_neib);
           image(i_neib, j_neib, :) = pix_result;
           F(i_neib, j_neib) = 1; %内部点变成边缘点
       end
    end
end
end

function [ pix_result ] = inpaint_p( image, T, F, neibor_is, neibor_js, i_neib, j_neib )
%根据内部点（i_neib, j_neib）领域中已知点的像素值插值计算该内部点的像素值
    pix_sum = 0.0;
    weight_sum = 0.0;
    
    grad_i = gradient_i(T, F, i_neib, j_neib);
    grad_j = gradient_j(T, F, i_neib, j_neib);

    for m=1:length(neibor_is)
        i_neib_neib = i_neib+neibor_is(m);
        j_neib_neib = j_neib+neibor_js(m);
        
        if i_neib_neib<=0 || i_neib_neib>size(T,1) || j_neib_neib<=0 || j_neib_neib>size(T,2)
            continue;
        end
        
        if F(i_neib_neib, j_neib_neib) ~= 2 % 已知像素点
            dx = i_neib - i_neib_neib;
            dy = j_neib - j_neib_neib;
            
            dst = 1 / ((dx^2 + dy^2) * sqrt(dx^2 + dy^2));
            lev = 1 / (1 + abs(T(i_neib_neib, j_neib_neib) - T(i_neib, j_neib)));
            dir = abs(dx * grad_i + dy * grad_j);
            if dir==0
                dir=1e-6;
            end
            weight = dst * lev * dir;
            pix_sum = pix_sum + weight * double(image(i_neib_neib, j_neib_neib, :));
            weight_sum = weight_sum + weight;
           
        end
    end
    pix_result = uint8(pix_sum ./ weight_sum);
end

%参考https://github.com/eodos/inpainting-telea-matlab
function [ grad ] = gradient_i( image, F, i, j )
    if (i+1<size(F,1))&&(F(i+1, j) ~= 2) 
        if (i-1>0)&&(F(i-1, j) ~= 2)
            grad = (image(i+1, j) - image(i-1, j))/2;

        else
            grad = image(i+1, j) - image(i, j);
        end
    else
        
        if (i-1>0)&&(F(i-1, j) ~= 2)
            grad = image(i, j) - image(i-1, j);
        else
            grad = 0;
        end
    end
end

%参考https://github.com/eodos/inpainting-telea-matlab
function [ grad ] = gradient_j( image, F, i, j )
    if (j+1<size(F,2))&&(F(i, j+1) ~= 2) 
        if (j-1>0)&&(F(i, j-1) ~= 2) 
            grad = (image(i, j+1) - image(i, j-1))/2;
        else
            grad = image(i, j+1) - image(i, j);
        end
    else
        if (j-1>0)&&(F(i, j-1) ~= 2) 
            grad = image(i, j) - image(i, j-1);
        else
            grad = 0;
        end
    end
end




