# 图像去遮挡
本项目用FMM算法和criminisi算法实现图像修复
## 可执行程序
可程序程序带有UI用户界面，在Windows系统下打开“可执行程序\mygui\for_testing\mygui.exe”来使用。
在下拉框中选择要处理的图片，点击“获取mask”自动获得栏杆的位置，再点击“修复图像”得到修复结果。
## code
- mygui.m: UI用户界面的代码
- main1.m: 获取图片一的mask并修复，主逻辑代码。
- main2.m: 获取图片二的mask并修复，主逻辑代码。
### get_mask
- get_mask_1.m: 检测图片一中栏杆的位置。
- get_mask_2.m: 检测图片二中栏杆的位置，返回两个mask，thick_mask是宽栏杆的mask，thin_mask是扁栏杆的mask。
- get_hough_lines.m: hough变换提取图片中的直线，部分摘抄自：https://blog.csdn.net/yufeilongyuan/article/details/90443933
- lines_integrate.m: 对hough变换检测到的直线做进一步处理，将lines中重复的直线去掉，并化成角度距离型
- maskFromlines.m: 利用直线位置得到mask，在直线附近灰度值低的部分mask值为1，其他部分mask为0.
### FFM_inpaint
- inpaint_FMM.m: FMM算法的初始化和主循环。
- compute_outside.m: 计算一部分外部点（已知像素值点）的T矩阵值。
- myMinheap.m: 最小堆类，部分参考自：matlab建立最小堆算法实现 https://blog.csdn.net/YDY5659150/article/details/102928564 
- solve_T.m: 计算一个像素点的T值。
### criminisi_inpaint
- inpaint_criminisi.m: criminisi算法的初始化和主循环。
- bestMatch.m: 寻找处于边缘的补丁块的最佳已知图像块。
- bestMatch_fast.m: bestMatch.m的快速算法。