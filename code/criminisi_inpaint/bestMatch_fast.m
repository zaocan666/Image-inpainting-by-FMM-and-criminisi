function [best_match_is, best_match_js] = bestMatch_fast(p_is, p_js, mask, img_lab, search_radius)
    % 寻找处于边缘的补丁块的最佳已知图像块，快速算法。
    i_len = length(p_is);
    j_len = length(p_js);
    patch_img = img_lab(p_is, p_js, :);
    patch_mask = mask(p_is,p_js);
    min_dis = 1e9;
    
    up_search = max(p_is(1)-search_radius, 1);
    left_search = max(p_js(1)-search_radius, 1);
    down_search = min(p_is(end)+search_radius, size(mask, 1)-i_len+1);
    right_search = min(p_js(end)+search_radius, size(mask,2)-j_len+1);
    
    for i=up_search:down_search
       for j = left_search:right_search %i,j是补丁块的左上角
           match_is = i:i+i_len-1;
           match_js = j:j+j_len-1;
           match_mask = mask(match_is, match_js);
           if ~isempty(find(match_mask,1)) %match块有未知像素点
               continue;
           end
           
           match_img = img_lab(match_is, match_js, :);
           distance_pix = (patch_img-match_img).^2;
           distance_pix(repmat(patch_mask>0,[1 1 3]))=0;
           dis = sum(sum(sum(distance_pix)));
           if dis<=min_dis
              min_dis = dis;
              best_match_is=match_is;
              best_match_js=match_js;
           end
           
       end
    end
end