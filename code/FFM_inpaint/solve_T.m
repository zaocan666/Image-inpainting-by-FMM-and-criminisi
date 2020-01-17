function [ sol ] = solve_T( T, F, i1, j1, i2, j2 )
% 计算一个像素点的T值
    sol = 1e6;
    if i1<1 || i1>size(F,1) || j1<1 || j1>size(F,2)
        return;
    end
    if i2<1 || i2>size(F,1) || j2<1 || j2>size(F,2)
        return;
    end
    
    T1 = T(i1, j1);
    T2 = T(i2, j2);

    if F(i1, j1) == 0 %已知
        if F(i2, j2) == 0 %已知
            r = sqrt(2 - (T1 - T2)^2);
            s = (T1 + T2 - r) * 0.5;
            if (s >= T1 && s >= T2)
                sol = s;
            else
                s = s + r;
                if(s >= T1 && s >= T2)
                    sol = s;
                end
            end
        else
            sol = 1 + T1;
        end
    elseif F(i2, j2) == 0
        sol = 1 + T2;
    end
end

