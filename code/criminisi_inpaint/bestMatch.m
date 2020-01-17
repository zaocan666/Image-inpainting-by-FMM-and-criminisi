function [best_match_is, best_match_js] = bestMatch(p_is, p_js, mask, img_lab)
    % Ñ°ÕÒ´¦ÓÚ±ßÔµµÄ²¹¶¡¿éµÄ×î¼ÑÒÑÖªÍ¼Ïñ¿é
    i_len = length(p_is);
    j_len = length(p_js);
    patch_img = img_lab(p_is, p_js, :);
    patch_mask = mask(p_is,p_js);
    min_dis = 1e9;
    for i=1:size(mask, 1)-i_len+1
       for j = 1:size(mask,2)-j_len+1 %i,jÊÇ²¹¶¡¿éµÄ×óÉÏ½Ç
           match_is = i:i+i_len-1;
           match_js = j:j+j_len-1;
           match_mask = mask(match_is, match_js);
           if ~isempty(find(match_mask,1)) %match¿éÓÐÎ´ÖªÏñËØµã
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