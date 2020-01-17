function [result_img] = inpaint_criminisi(img, mask, patch_size, speed)
    %criminisi算法的初始化和主循环
    %修补块的大小为pitch_size*pitch_size, patch_size需要为奇数
    %mask应该为0 1矩阵，为1的部分是需要修复的部分
    img = double(img);
    img_lab = rgb2lab(img);
    
    C = double(~mask); %C的初始化
    
    %求Ip，图片像素值梯度的等长垂线
    [gradient_i1, gradient_j1] = gradient(img(:,:,1));
    [gradient_i2, gradient_j2] = gradient(img(:,:,2));
    [gradient_i3, gradient_j3] = gradient(img(:,:,3));
    gradient_i = double(gradient_i1+gradient_i2+gradient_i3)/3.0;
    gradient_j = double(gradient_j1+gradient_j2+gradient_j3)/3.0;
    Ip_i = -gradient_j/255.0;
    Ip_j = gradient_i/255.0; %梯度转90度
    
    SE=strel('square',3);%矩形mask
    size_img = size(img);
    pSize_half = (patch_size-1)/2;
    
    mask_sum = sum(sum(mask));
    while mask_sum > 0
        %求边缘点
        fat_mask = imdilate(mask, SE); %mask膨胀
        contour_mart = fat_mask-mask; %mask的边缘
        contour_index = find(contour_mart>0);
        
        %计算每个边缘点的C
        for i=1:length(contour_index) 
            c = contour_index(i);
            [c_i, c_j] = getIJ_index(round(c), size_img(1));
            [i_neibor, j_neibor] = get_neiborIndex(c_i, c_j, pSize_half, size_img);
            C_patch = C(i_neibor, j_neibor);
            C(c_i, c_j) = double(sum(sum(C_patch)))/double(numel(C_patch));
        end
        
        %计算待修复区域边缘线的垂线
        [np_i, np_j] = gradient(double(~mask));
        np_dis = sqrt(np_i.^2+np_j.^2);
        %np_dis(np_dis==0)=1e-6;
        np_i = np_i./np_dis;
        np_j = np_j./np_dis;%图像mask边缘的梯度，化成单位向量
        %np_i(isnan(np_i))=0;
        %np_j(isnan(np_j))=0;
        np_i(~isfinite(np_i))=0;
        np_j(~isfinite(np_j))=0;
        
        %边缘点的D值
        D_contour = np_i(contour_index).*Ip_i(contour_index) + np_j(contour_index).*Ip_j(contour_index);
        D_contour = abs(D_contour);
        %D_contour(D_contour<1e-6)=1e-6;
        D_contour=D_contour+1e-3;
        
        %算出边缘点优先级，并取优先级最高的点
        Priority_contour = D_contour.* C(contour_index); 
        [~, best_index] = max(Priority_contour);
        best_contour = contour_index(best_index);
        [bC_i, bC_j] = getIJ_index(best_contour, size(img,1));
        [i_neibors, j_neibors] = get_neiborIndex(bC_i, bC_j, pSize_half, size_img);
        
        %img1 = img_lab(:,:,1);
        %找到匹配度最高的块
        if speed=='fast'
            [best_match_is, best_match_js] = bestMatch_fast(i_neibors, j_neibors, mask, img_lab, patch_size*9);
        else
            [best_match_is, best_match_js] = bestMatch(i_neibors, j_neibors, mask, img_lab); 
        end
        
        %复制像素值
        img(i_neibors, j_neibors, :) = img(best_match_is, best_match_js,:); %复制图像块rgb值
        img_lab(i_neibors, j_neibors, :) = img_lab(best_match_is, best_match_js,:); %复制图像块lab值
        
         %更新C
        mask_patch = mask(i_neibors,j_neibors);
        unknow_pNum = sum(sum(double(mask_patch)));
        C_patch = C(i_neibors, j_neibors);
        C_patch(mask_patch>0)=C(bC_i,bC_j);
        C(i_neibors, j_neibors) = C_patch;
        
        %更新mask
        mask(i_neibors,j_neibors)=0; 
        
        mask_sum = mask_sum-unknow_pNum
    end
    
    result_img = img;
end

%获得一块pitch中的行和列
function [is, js] = get_neiborIndex(center_i, center_j, half_len, size_img)
    up = max(center_i-half_len, 1);
    down = min(center_i+half_len, size_img(1));
    left = max(center_j-half_len, 1);
    right = min(center_j+half_len, size_img(2));
    is = up:down;
    js = left:right;
end

function [i, j] = getIJ_index(index, rowNum)
    j = floor((index-1)/rowNum)+1;
    i = rem(index-1,rowNum)+1;
end