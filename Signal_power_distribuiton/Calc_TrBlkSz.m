function [ TrBlkSz ] =  Calc_TrBlkSz( RB, MCS )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
load('MCS_to_Itbs.mat')
%This is in form MCS_Index (0 - 31), Modulation Index, (2-6),
%TBS_Index(0-26)
%Retrieve transport block index from here
Itbs = MCStoItbs( (MCS+1), 3);

load('Itbs_to_TBS.mat')
%This is in form:
%y-axis (rows) are Itbs (0-33)
%x-axis (columns) are NULRB (1-110)
TrBlkSz = TBS((Itbs+1), RB); 

clear('TBS','MCStoItbs')

end

