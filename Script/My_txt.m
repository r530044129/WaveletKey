% create scales
numOctave = 8;
numVoices = 32;
s0=1;
a0=2^(1/numVoices);
scales=s0*a0.^(0:numOctave*numVoices);

% 4 coefs to 1 coefs ,72 frame to 18 frame
for V=100:300
    for H=200:400
        
%         ������x ���������.(��˹ȡ��)
        MeanSignalCount = floor(fileCount/4);
%         ��������ȡ��
        MeanPixelSignal=round((maskOutPutSequence(V,H,1)+maskOutPutSequence(V,H,2)+maskOutPutSequence(V,H,3)+maskOutPutSequence(V,H,4))/4);
        for Count = 2:MeanSignalCount
%                 StartCount
            u=(Count-1)*4;
            MeanPixelSignal=[MeanPixelSignal,round((maskOutPutSequence(V,H,u)+maskOutPutSequence(V,H,u+1)+maskOutPutSequence(V,H,u+2)+maskOutPutSequence(V,H,u+3))/4)];
        end
        
        for frame=1:MeanSignalCount
        MeanOutPutSequence_1to4(V,H,frame)=MeanPixelSignal(frame);        
        end
    end
end
imshow(MeanOutPutSequence_1to4(100:300,200:400,1),[0,50])

% dowmsample:3 frame to 1 frame
for V=100:300
    
    for H=200:400
        
        singlePixelSignal=imageArray(V,H,1);
        
        for frame=2:fileCount
            singlePixelSignal=[singlePixelSignal,imageArray(V,H,frame)];            
        end
        
        singlePixelSignal_dowmsample = singlePixelSignal(1:3:fileCount);
        coeffecients_dowmsample = cwt(singlePixelSignal_dowmsample,CWTScale,motherWavelet);

        for frame=1:24
        maskOutPutSequence_dowmsample(V,H,frame)=uint16(abs(coeffecients_dowmsample(frame)));
        end        
    end
end
% save maskOutPutSequence data
DataName=strcat('Data\MOPS_',motherWavelet,'_',num2str(CWTScale),'.mat');
save(DataName,'maskOutPutSequence');

imshow(maskOutPutSequence_dowmsample(100:300,200:400,1),[0,50])

plot(maskOutPutSequence_dowmsample(100,200:240,1));
hold on;
plot(maskOutPutSequence(100,200:240,1),':');

for k=1:M*N
    %M*N,����
    %�к�
    i=mod(k-1,M)+1;
    %�к�
    j=floor((k-1)/M)+1;
end

view(az,el)    

% ������
h = waitbar(0,'Please wait...');
        for i=1:1000
            % computation here %
            str=['�Ż�������...',num2str(i/10),'%'];
            waitbar(i/1000,h,str);
%                 waitbar(i/10000,h);
        end;
% close(h)

clampBottom=0;
%White
clampHead=15;
alphaSequence16=(((maskOutPutSequence(:,:,40)-clampBottom))*256)/(clampHead-clampBottom);

if ~exist('2Figure') 
    mkdir('2Figure')         % �������ڣ��ڵ�ǰĿ¼�в���һ����Ŀ¼��Figure��
end 

BW=imread('testPic.tif');
% AW=BW;
AW=255-BW;
% for i=1:1080
% for j=1:1920
% if AW(i,j)>120
% AW(i,j)=0;
% else
% AW(i,j)=1;
% end
% end
% end
SE=strel('square',3);
% SE = offsetstrel('ball',3,3);
AW_erode=imerode(AW,SE);
AW_dilate=imdilate(AW,SE);
AW_erode_dilate=imdilate(AW_erode,SE);
AW_dilate_erode=imdilate(AW_dilate,SE);
figure(3);imshow(AW,[]);title('ԭͼ');
figure(4);imshow(AW_erode,[]);title('��ʴ');
figure(5);imshow(AW_dilate,[]);title('����');
figure(6);imshow(AW_erode_dilate,[]);title('������');
figure(7);imshow(AW_dilate_erode,[]);title('������');

AW_open_minus_original=AW-AW_erode_dilate;
figure(8);title('�������ԭͼ');imshow(AW_open_minus_original,[]);

% 如果运行出现错误，matlab会自动停在出错的那行，并且保存所有相关变量
dbstop if error

array(array>1)=0;
array(and(array>1,array<3))=0;

fig = figure;
fig.Position = get(0,'ScreenSize');
plot(1:10);
zoom on

% Find the influenced frame by the certain scale of certain wavelet
m=12;
Signal = plotContainer(1:2*m);
Signal_a=Signal;
Signal_b=Signal;
Signal_b(m)=100;

wavelet = 'bior3.3';
scale = 2;
a = cwt(Signal_a,scale,wavelet); 
b = cwt(Signal_b,scale,wavelet); 

front=0;back=0;
for i=1:m-1
    front(a(i)~=b(i))=front+1;
end
for i=m+1:2*m
    back(a(i)~=b(i))=back+1;
end

% Create video
v=VideoWriter('Video','MPEG-4');
v.FrameRate=24;
open(v);
for i=1:60
OneMaskedPicName = strcat('MaskedPic.',num2str(2*i-1),'.png');
OneMaskedPic = imread(OneMaskedPicName);
writeVideo(v,OneMaskedPic);
end
close(v);

load('plotContainer_555,1400.mat')
pc=plotContainer;
a=cwt(pc,2,'bior1.1');
b=cwt(pc,4,'bior1.1');
a=abs(a);b=abs(b);
c=abs(a-b);
subplot(311);plot(a);subplot(312);plot(b);subplot(313);plot(c);

%Denoisy
V1=1;V2=Vres;
deltaV=V2-V1;
h = waitbar(0,'Please wait...');
timeStart = tic;
for V=V1:V2
    for H=1:Hres
        singlePixelSignal=[];
        for frame=1:fileCount           
            singlePixelSignal=[singlePixelSignal,maskOutPutSequence(V,H,frame)];
        end
        xd = wden(singlePixelSignal,'minimaxi','s','mln',5,'sym5');
        for frame=1:fileCount
             maskOutPutSequence_denoisy(V,H,frame)=uint16(abs(xd(frame)));
        end
        str=['Denoisy-请等待...',num2str((V-V1)/deltaV*100),'%'];
        waitbar((V-V1)/deltaV,h,str);
    end
end
timeOver = toc(timeStart);