%ChooseMotherWavelet
motherWavelet='bior1.1';
CWTScale=2;

% ----------------------------------------------------------------

% Path
fileMotherPath='Test-source/';
SourcePath='Transparent/1';

outPutDataPath=strcat('Data/',SourcePath,'/');
if ~exist(outPutDataPath) 
    mkdir(outPutDataPath)         
end 

filePath=strcat(fileMotherPath,SourcePath,'/');
filePathList=dir(strcat(filePath,'*.jpg'));

% Variable
fileCount = 120;
%image vertical and horizontal resolution
Vres=1080;
Hres=1920;
imageArray=zeros(Vres,Hres,fileCount);
%create fileCount room
maskOutPutSequence=zeros(Vres,Hres,fileCount);

outPutFilePath=strcat('OutPut/',SourcePath);
if ~exist(outPutFilePath) 
    mkdir(outPutFilePath)         
end 
outPutFileWaveletPath=strcat(outPutFilePath,'/',motherWavelet,'_',num2str(CWTScale));
if ~exist(outPutFileWaveletPath) 
    mkdir(outPutFileWaveletPath)         
end 

%Read all image sequence into imageArray
for u=1:fileCount
%   imageName=filePathList((9*(u-1))+1).name;
   imageName=filePathList(u).name;
  a=strcat(filePath,imageName);
  imageArray(:,:,u)=rgb2gray(imread(a));
end

% ----------------------------------------------------------------

% cwt
V1=1;V2=Vres;
deltaV=V2-V1;
h = waitbar(0,'Please wait...');
timeStart = tic;
for V=V1:V2
    for H=1:Hres
        singlePixelSignal=[];
        for frame=1:fileCount           
            singlePixelSignal=[singlePixelSignal,imageArray(V,H,frame)];
        end
        coeffecients=cwt(singlePixelSignal,CWTScale,motherWavelet);
        for frame=1:fileCount
             maskOutPutSequence(V,H,frame)=uint16(abs(coeffecients(frame)));
        end
        str=[SourcePath,'-',motherWavelet,'-',num2str(CWTScale),'-请等待...',num2str((V-V1)/deltaV*100),'%'];
        waitbar((V-V1)/deltaV,h,str);
    end
end
timeOver = toc(timeStart);

% save maskOutPutSequence data
DataName = strcat('extract',num2str(fileCount),'_MOPS_',motherWavelet,'_',num2str(CWTScale),'_',num2str(round(timeOver/60)),'mins','.mat');
DataNamePath=strcat(outPutDataPath,DataName);
save(DataNamePath,'maskOutPutSequence');

% ----------------------------------------------------------------

% show surf
frame = floor(fileCount/2);
% frame =10;
surf(maskOutPutSequence(:,:,frame));
shading interp;view(0,-90);title(strcat(motherWavelet,'-',num2str(frame)));

% ----------------------------------------------------------------

%Black
clampBottom=60;
%White
clampHead=180;
% save masked pic
clampDelta=clampHead-clampBottom;
alphaSequence16=zeros(Vres,Hres,fileCount);

outPutFileWaveletAlphaPath=strcat(outPutFileWaveletPath,'/','Alpha_',num2str(clampBottom),'-',num2str(clampHead));
if ~exist(outPutFileWaveletAlphaPath) 
    mkdir(outPutFileWaveletAlphaPath)        
end 
outPutFileWaveletAlphaMaskPath=strcat(outPutFileWaveletAlphaPath,'/','Mask');
if ~exist(outPutFileWaveletAlphaMaskPath) 
    mkdir(outPutFileWaveletAlphaMaskPath)        
end 
for j=1:fileCount
    for m=1:1080
        for n=1:1920
            if maskOutPutSequence(m,n,j)>clampHead
                alphaSequence16(m,n,j)=0;
            elseif maskOutPutSequence(m,n,j)<clampBottom
                    alphaSequence16(m,n,j)=1;
            else
                alphaSequence16(m,n,j)=(clampHead-maskOutPutSequence(m,n,j))/clampDelta;
            end
        end
    end
    outPutFileName_temp=strcat(outPutFileWaveletAlphaMaskPath,'/outPutAlpha','.',int2str(j),'.tif');
    imwrite(alphaSequence16(:,:,j),outPutFileName_temp);
end

% ----------------------------------------------------------------

outPutFileWaveletMaskedPath=strcat(outPutFileWaveletAlphaPath,'/','Masked');
if ~exist(outPutFileWaveletMaskedPath) 
    mkdir(outPutFileWaveletMaskedPath)         
end 
% save masked pic
for j=1:fileCount
    imageName=strcat(filePath,filePathList(j).name);
    I2=imread(imageName);
    MaskedOutPutFileName=strcat(outPutFileWaveletMaskedPath,'/','MaskedPic.',int2str(j),'.png');
    imwrite(I2,MaskedOutPutFileName,'Alpha',alphaSequence16(:,:,j));
end

% ----------------------------------------------------------------

% create masked pic video
outPutFileWaveletMaskedVideoPath=strcat(outPutFileWaveletAlphaPath,'/','MaskedVideo');
if ~exist(outPutFileWaveletMaskedVideoPath) 
    mkdir(outPutFileWaveletMaskedVideoPath)         
end
VideoName = strcat(outPutFileWaveletMaskedVideoPath,'/','Video');
v=VideoWriter(VideoName,'MPEG-4');
v.FrameRate=24;
open(v);
for i=1:fileCount/2
OneMaskedPicName = strcat(outPutFileWaveletMaskedPath,'/','MaskedPic.',num2str(2*i-1),'.png');
OneMaskedPic = imread(OneMaskedPicName);
writeVideo(v,OneMaskedPic);
end
for i=1:fileCount/2
OneMaskedPicName = strcat(outPutFileWaveletMaskedPath,'/','MaskedPic.',num2str(2*i),'.png');
OneMaskedPic = imread(OneMaskedPicName);
writeVideo(v,OneMaskedPic);
end
close(v);

% WSDataName = strcat(outPutDataPath,'ws_',DataName);
% save(WSDataName);
