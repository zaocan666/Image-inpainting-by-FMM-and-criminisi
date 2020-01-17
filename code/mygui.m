function varargout = mygui(varargin)
% MYGUI MATLAB code for mygui.fig
%      MYGUI, by itself, creates a new MYGUI or raises the existing
%      singleton*.
%
%      H = MYGUI returns the handle to a new MYGUI or the handle to
%      the existing singleton*.
%
%      MYGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MYGUI.M with the given input arguments.
%
%      MYGUI('Property','Value',...) creates a new MYGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before mygui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to mygui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help mygui

% Last Modified by GUIDE v2.5 25-Nov-2019 09:35:16

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @mygui_OpeningFcn, ...
                   'gui_OutputFcn',  @mygui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before mygui is made visible.
function mygui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mygui (see VARARGIN)

% Choose default command line output for mygui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes mygui wait for user response (see UIRESUME)
% uiwait(handles.figure1);
addpath(genpath('FFM_inpaint'));
addpath(genpath('get_mask'));
addpath(genpath('criminisi_inpaint'));

set(figure,'Visible','off');

global I1_g I2_g I1_mask I2_mask;
I1_mask=[];
I2_mask=[];
img1 = imread('img1.JPG');
img1 = imresize(img1, 0.4); %为了提高运算速度，缩小图片
I1_g = img1;

img2 = imread('img2.JPG');
img2 = imresize(img2, 0.2); %缩小图片
I2_g = img2;

axes(handles.axes1);
imshow(img1);

% --- Outputs from this function are returned to the command line.
function varargout = mygui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in popupmenu1.
function popupmenu1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu1
global I1_g I2_g;
pic_num=get(hObject,'Value');
if pic_num==1
    img = I1_g;
else
    img = I2_g;
end
axes(handles.axes1);
imshow(img);


% --- Executes during object creation, after setting all properties.
function popupmenu1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_mask.
function pushbutton_mask_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_mask (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global I1_g I2_g I1_mask I2_mask line2_thick_mask;
pic_num=get(handles.popupmenu1,'Value');
if pic_num==1
   I1_gray = rgb2gray(I1_g);
   I1_mask = get_mask_1(I1_gray, floor(509*size(I1_gray,1)/719)); 
   mask=I1_mask;
else
    I2_gray = rgb2gray(I2_g);
    [line2_thick_mask, line2_thin_mask] = get_mask_2(I2_gray, floor(716*size(I2_gray,1)/1210));
    I2_mask = line2_thick_mask+line2_thin_mask;
    I2_mask(I2_mask>0)=255;
    mask = I2_mask;
end
axes(handles.axes_mask);
imshow(mask);


% --- Executes on button press in pushbutton_inpaint.
function pushbutton_inpaint_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_inpaint (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global I1_g I2_g I1_mask I2_mask line2_thick_mask;
pic_num=get(handles.popupmenu1,'Value');
if pic_num==1
    if isempty(I1_mask)
        h=warndlg('请先按“获取mask”按钮','警告','modal');
        return;
    end
    result_img = inpaint_FMM( I1_g, uint8(I1_mask/255), 3 );
else
    if isempty(I2_mask)
        h=warndlg('请先按“获取mask”按钮','警告','modal');
        return;
    end
    %先用FFM算法进行修复
    scale2=0.5;
    I2_small = imresize(I2_g, scale2); %再次缩小图片，较少运算时间
    mask_thick_small = imresize(line2_thick_mask, scale2); 
    mask2_small = imresize(I2_mask, scale2);
    result_ffm_img = inpaint_FMM( I2_small, uint8(mask2_small/255), 3 ); 

    %用criminisi算法对宽栏杆部分进行修复
    result_img = inpaint_criminisi(result_ffm_img, mask_thick_small>0, 3, 'fast');
end
axes(handles.axes_out);
imshow(uint8(result_img));
msgbox('修复完成','提示');
