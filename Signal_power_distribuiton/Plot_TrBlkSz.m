clear all
close all
maxRB = 100;
maxMCS = 23;
MCS_Idx = (0:1:maxMCS)';
RB_Idx = (1:1:maxRB);
TrBlkSz = zeros(maxMCS, maxRB);


for MCS = 0:maxMCS
    for RB = 1:maxRB
        TrBlkSz(MCS+1, RB) = Calc_TrBlkSz( RB, MCS )/8;
    end
end
figure()
surf (RB_Idx, MCS_Idx, TrBlkSz)
    title('Transport Block Size - 1 subframe (1ms)')
    xlabel('RB Allocation') % x-axis label
    ylabel('MCS Index') % y-axis label
    zlabel('Transport Block Size (bytes)') % y-axis label
    xlim ([0 maxRB])
    ylim ([0 maxMCS])
    
figure()
contour3(RB_Idx, MCS_Idx, TrBlkSz,'ShowText','on')
    title('Transport Block Size - 1 subframe (1ms)')
    xlabel('RB Allocation') % x-axis label
    ylabel('MCS Index') % y-axis label
    zlabel('Transport Block Size (bytes)') % y-axis label