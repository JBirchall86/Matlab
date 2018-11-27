clear all
close all
%% To Do:

% Check on windowing required in SC-FDMA modulate
% Add PRACH support?
% Figure out how MCS schemes are implemented
% Check random data generation
% Analyse throughput test for any improvement.


%% Need to create parameter structure:
ue = struct;
ue.NULRB = 6;                  % Number of resource blocks
ue.NCellID = 10;                % Physical layer cell identity
ue.Hopping = 'Off';             % Disable frequency hopping
ue.CyclicPrefixUL = 'Normal';   % Normal cyclic prefix
ue.DuplexMode = 'FDD';          % Frequency Division Duplex (FDD)
ue.NTxAnts = 1;                 % Number of transmit antennas
ue.NFrame = 0;                  % Frame number
ue.SeqGroup =0;
ue.NSubframe = 0; 
ue.RNTI = 1;

ue.CyclicShift = 0;
ue.Shortened = 0;

%% Configure the PUSCH. In addition to the UE settings specified in ue, you 
% must define parameters related to the physical channel to generate the PUSCH.
ue.pusch.PRBSet = (0:5).';
ue.pusch.Modulation = 'QPSK';
ue.pusch.RV = 0;
ue.pusch.DynCyclicShift = 0;
ue.pusch.NLayers = 1;
ue.pusch.OrthCover = 'Off';


%% Setup number of loops
numRuns = 1000; % Number of iterations.

papr = zeros(6,numRuns); % Initialize the PAPR results.


ue.pusch.Modulation = 'QPSK';

for bw = 1:6,
ue.pusch.PRBSet = (0:(bw-1)).';   
for n = 1:numRuns,
%% Generate empty resource grid for one subframe
subframe = lteULResourceGrid(ue);

% Generate the UL-SCH message. To do so, call the function lteULSCH, 
trblk = round(rand(1,504));
cw = lteULSCH(ue,ue.pusch,trblk);

puschSymbols = ltePUSCH(ue,ue.pusch,cw);
puschIndices = ltePUSCHIndices(ue,ue.pusch);
drsSymbols = ltePUSCHDRS(ue,ue.pusch);
drsIndices = ltePUSCHDRSIndices(ue,ue.pusch);
subframe(puschIndices) = puschSymbols;
subframe(drsIndices) = drsSymbols;

% Final stuff for generating wavefo,
%  performs IFFT calculation, half-subcarrier shifting, and cyclic prefix 
%  insertions. It optionally performs raised-cosine windowing and overlapping
%  of adjacent SC-FDMA symbols of the complex symbols in the resource array, 
%  grid.
[waveform,info] = lteSCFDMAModulate(ue,subframe);
papr(n,bw) = 10*log10(max(abs(waveform).^2) / mean(abs(waveform).^2));

end
end

%for bw = 1:6,
bw=1;
[N(:,bw),X(:,bw)] = hist(papr(:,bw), 100);
semilogy(X(:,bw),1-cumsum(N(:,bw))/max(cumsum(N(:,bw))),'r');
hold on

bw=2;
[N(:,bw),X(:,bw)] = hist(papr(:,bw), 100);
semilogy(X(:,bw),1-cumsum(N(:,bw))/max(cumsum(N(:,bw))),'g');

bw=3;
[N(:,bw),X(:,bw)] = hist(papr(:,bw), 100);
semilogy(X(:,bw),1-cumsum(N(:,bw))/max(cumsum(N(:,bw))),'b');

bw=4;
[N(:,bw),X(:,bw)] = hist(papr(:,bw), 100);
semilogy(X(:,bw),1-cumsum(N(:,bw))/max(cumsum(N(:,bw))),'k');

bw=5;
[N(:,bw),X(:,bw)] = hist(papr(:,bw), 100);
semilogy(X(:,bw),1-cumsum(N(:,bw))/max(cumsum(N(:,bw))),'c');

bw=6;
[N(:,bw),X(:,bw)] = hist(papr(:,bw), 100);
semilogy(X(:,bw),1-cumsum(N(:,bw))/max(cumsum(N(:,bw))),'m');


%end




title('PAPR Distribution')
xlabel('PAPR (dB)') % x-axis label
ylabel('Occurence') % y-axis label
labels = {'RB-1','RB-2','RB-3','RB-4','RB-5','RB-6'};
legend(labels,'Location','southoutside','Orientation','horizontal')


figure
bandwidth = [1,2,3,4,5,6];
for a = 1:6,
mean_papr(a) = mean(papr(:,a));
end
plot(bandwidth,mean_papr)
xlabel('Bandwidth (Resource Blocks)') % x-axis label
ylabel('Mean PAPR (dB)') % y-axis label
% Compute spectrogram
% [y,f,t,p] = spectrogram(waveform, 512, 0, 512, info.SamplingRate);
% 
% % Re-arrange frequency axis and spectrogram to put zero frequency in the
% % middle of the axis i.e. represent as a complex baseband waveform
% f = (f-info.SamplingRate/2)/1e6;
% p = fftshift(10*log10(abs(p)));
% 
% % Plot spectrogram
% figure;
% surf(t*1000,f,p,'EdgeColor','none');
% xhandle = xlabel('Time (ms)');
% yhandle = ylabel('Frequency (MHz)');
% zhandle = zlabel('Power (dB)');
% tithandle = title('Spectrogram of Test Model ');
% 
% set(xhandle,'Fontsize',20);
% set(zhandle,'Fontsize',20);
% set(yhandle,'Fontsize',20);
% set(tithandle,'Fontsize',25);

