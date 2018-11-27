%% Tidy up
clear all
close all

%% Set current folder
%inputFolder = input('Please enter folder name:','s'); 
for b = 1:2

save_str = ['MCS23_',num2str(b)];
%myFolder = 'C:\Labview\VarMCS_512B_2';
myFolder = ['\\ads.bris.ac.uk\filestore\MyFiles\Students\jb13370\Documents\Project\IWCMC\Matlab\Labview\',save_str];
if ~isdir(myFolder)
errorMessage = sprintf('Error: The following folder does not exist:\n%s', myFolder);
uiwait(warndlg(errorMessage));
return;
end
filePattern = fullfile(myFolder, '*.lvm');
lvmFiles = dir(filePattern);
dateStr=strcat(lvmFiles(1).name(1:8));
%% Load all .lvm files in directory
% Set up filenames
exponents = 3:1:14;
Datasize = 2.^exponents; 
for j=1:size(Datasize,2)

baseFileName = strcat(dateStr,'-',num2str(Datasize(j)),'B'); 
fullFileName = fullfile(myFolder, baseFileName);

%   fprintf(1, 'Now reading %s\n', fullFileName);

 
%Import lvm data
lvmData = lvm_import(fullFileName);

samplePeriod = lvmData.Segment1.Delta_X(1,1);

%% Insert calibration file application here 
numSamples = length(lvmData(1,1).Segment1.data(:,1));
% Pre allocate current array



%% Pull data for time and RF power
time = lvmData.Segment1.data(:,1);
%Apply correction to RF data
RFPower = (lvmData.Segment1.data(:,4)).*47.364 -70.816;
PRFW = (10.^(RFPower./10))./1000; 

Vcc = lvmData.Segment1.data(:,2);
Is = (lvmData.Segment1.data(:,3)).*0.4842 + 0.0006;
Pdc = Vcc .* Is;

%Free up memory
%clear lvmData
clear Vcc
clear Is


%% Do some analysis
% Want: No. sections
%       Total RF energy transmitted
%       
Energy = 0;
RFEnergy = 0;
Transmissions = 0;

RFPower2 = 0;
time2 = 0;
% Thresholding exercise:
for i = 1:size(time)-1
    if RFPower(i) > -30
        RFPower2 = [RFPower2 ; RFPower(i)];
        time2 = [time2 ; time(i)];
    end
        
% Whilst not at the end of data set, integrate energy consumed        
    if time(i+1) == time(i) + samplePeriod
        Energy = Energy + (samplePeriod * ((Pdc(i) + Pdc(i+1))/2));
        RFEnergy = RFEnergy + (samplePeriod * ((PRFW(i) + PRFW(i+1))/2));
    else
        Transmissions = Transmissions + 1;
    end
end

%% Plot data
Energy_consumed(j) = Energy; 
RFEnergy_consumed(j) = RFEnergy; 
Activity_Time(j) = max(time2);
TX_Time(j) = size(time2,1) * samplePeriod;
TX_Ratio(j) = (TX_Time(j) / Activity_Time(j)) * 100;


save(save_str,'Energy_consumed', 'Activity_Time', 'TX_Time', 'TX_Ratio','RFEnergy_consumed')
end

%fprintf(sprintf('Activity time = %4.3f sec \n',Activity_Time));
%fprintf(sprintf('TX time = %4.3f sec \n',TX_Time));
%fprintf(sprintf('TX ratio = %4.2f percent \n',TX_Ratio));

%RFPower = RFPower2;
%time = time2;

% RF_mean = mean(RFPower);
% figure(1)
% plot(time,RFPower)
% hold on
% plot([min(time) max(time)],[RF_mean RF_mean],'r')
%plotTitle = strcat('Power Consumption',baseFileName);
%title(plotTitle)
% xlabel('Time (s)') % x-axis label
% ylabel('RF Power (dBm)') % y-axis labeln ,
% 

%Stuff to zoom in
% figure(3)
% [N_Pdc,X_Pdc] = hist(Pdc, 100);
% plot(X_Pdc,N_Pdc,'b')
% xlabel('DC Power (W)') % x-axis label
% ylabel('Occurence') % y-axis label
%Calculate energy usage & time taken
end
plot(Datasize, Energy_consumed)
% semilogx(Datasize,TX_Ratio)
% xlabel('Packet size (Bytes)') % x-axis label
% ylabel('Transmission Ratio (%)') % y-axis labeln ,
% figure
% semilogx(Datasize, Energy_consumed)
% xlabel('Packet size (Bytes)') % x-axis label
% ylabel('Energy Consumed (J)') % y-axis labeln ,
% %save('Data_5.mat')
% figure(3)
% [N_Power,X_Power] = hist(RFPower2, 1000);
% plot(X_Power,N_Power,'b')
% xlabel('Power (dBm)') % x-axis label
% ylabel('Occurence') % y-axis label