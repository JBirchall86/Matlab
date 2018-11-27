clear all
close all


%% Calibration
%This is dependent on MCS &  BW
PXT_Offset = 5.33;

Amp_in_loss = -0.31;

PA_OP_Attenuator = 11.8;
%Includes any pads:
Amp_out_loss = 1.07 + PA_OP_Attenuator;


%% Steps:

% 1. Check for modem connection
% 2. Set power control to manual and minimise modem power
% 3. Initialise MAC padding
% 4. Set limits on power supply
% 5. Activate power supply outputs
% 6. Steadily send power increment messages until target Pout reached
% 7. Loop: Decrement Vcc
%           Check EVM & ACLR
% 8. Record Vcc, Is, P_in, P_out

[ChannelsObj, MeasObj] = init_power_sensor();

sport = serial('COM21');
init_GPIB(sport);

% get the connection with iTuner
iTuner = acquire_iTuner('10.0.0.2');
% Init iTuner, the slide screw probe will move to (0,0)
socket_query(iTuner, 'INIT');
% Welcome display on the screen, disply whatever you want
socket_query(iTuner, 'DISP        | JBirchall');
pause(10)

load ('Trajectories.mat')


%% Check for modem connection
UE_status = 'REG';
while UE_status ~= 'CON'
    UE_status = sprintf('%c',PXT_read('BSE:STATus:ACELL?',sport));
    pause(1);
end

% Set power control to manual and minimise modem power
PXT_write('BSE:FUNCtion:UE:POWer:CONTrol:MODE CLPControl', sport);
%PXT_write('BSE:FUNCtion:UE:POWer:CONtrol:ALLDown ON', sport);
pause(1);
%PXT_write('BSE:FUNCtion:UE:POWer:CONtrol:ALLDown OFF', sport);

% Initialise MAC padding
PXT_write('BSE:CONFig:PHY:UL:GRANt:MODE FIXEDMACpadding', sport);

% Set limits on power supply
DPS_write('OVSET 1,3.5',sport)
DPS_write('OVSET 2,3.5',sport)
DPS_write('OVSET 3,3.5',sport)
DPS_write('OVSET 4,3.5',sport)

DPS_write('ISET 1,0.1',sport)
DPS_write('ISET 2,0.1',sport)
DPS_write('ISET 3,0.6',sport)
DPS_write('ISET 4,0',sport)

% Activate power supply outputs
DPS_write('VSET 1,1.8',sport)
DPS_write('VSET 2,3.4',sport)
DPS_write('VSET 3,3.4',sport)
DPS_write('VSET 4,0',sport)

% Steadily send power increment messages until target Pout reached
%Set spectrum analyser mode, LTE, ACLR
PXT_write('SIGNal:MODE SA', sport);
PXT_write('SA:MODE LTE', sport);
PXT_write('SA:LTE:MODE ACLR', sport);

%Target_pout = [22 21 20 19 18 17 16 15 14 13 12 11 10 9 8 7 6 5 4 3 2 1 0 -1 -2 -3 -4 -5 -6 -7 -8];
Target_pout =  [-4 -5 -6 -7 -8];



PXT_write('BSE:FUNCtion:UE:POWer:CONTrol:MODE CLPControl', sport);
PXT_write('BSE:FUNCtion:UE:POWer:CONTrol:TARGet:PUSCh 0', sport);
PXT_write('BSE:FUNCtion:UE:POWer:CONTrol:TARGet:PUCCh 0', sport);



%Carrier power now stepped up to required level
%To check performance:
%Algorithm to alter Power supply voltage here
Voltage = 3.40;
for i= 1:size(Target_pout, 2)

% Increase supply voltage to negate gain compression at start of iteration

% Set power w/ CLPC initially
PXT_write('BSE:FUNCtion:UE:POWer:CONTrol:MODE CLPControl', sport);   
PXT_write(['BSE:FUNCtion:UE:POWer:CONTrol:TARGet:PUSCh',' ', num2str(Target_pout(i))], sport);
PXT_write(['BSE:FUNCtion:UE:POWer:CONTrol:TARGet:PUCCh',' ', num2str(Target_pout(i))], sport);
pause(1);
%Then disable CLPC to avoid it interferring with results
%PXT_write('BSE:FUNCtion:UE:POWer:CONTrol:MODE MANual', sport);

        Traj_index = 1;
        
for b = 1:(size(Traj,2)/2)
for a = 1:size(Traj,1)
    
    %Get x & y co-ordinates to send to tuner
    x_coord = Traj(a,(2*b)-1);
    y_coord = Traj(a,2*b);
    % Send to tuner
    iTuner_pos(iTuner, x_coord, y_coord);
    
    % Probably pause for a bit, maybe increase this
    pause(1)
    
    if a == 1
        % Long pause at start of each loop to allow tuner to reset
        pause(5)
    end
   
    iteration = 1;
    Results = Conformance_check(sport, iteration);
    Test_pass = Results(1);    
    PUSCH_EVM = Results(2);       
    Worst_ACLR = max(Results(4:7));


PXT_write('SA:LTE:MODE ACLR', sport);
pause(1)
ACLR_Summary = strsplit(sprintf('%c',PXT_read('LTE:ACLR:MEASure:TABLe?',sport)), ',');
Carrier_power = str2double(ACLR_Summary(1));
 
Test_result(i,Traj_index,:) = Results;

Pout_result(i, Traj_index) = Carrier_power + Amp_out_loss - PXT_Offset;
Vcc_result(i, Traj_index) = str2double(sprintf('%c',DPS_read('VOUT? 3', sport)));
Is_result(i, Traj_index) = str2double(sprintf('%c',DPS_read('IOUT? 3', sport)));
P_dc = Is_result(i, Traj_index) * Vcc_result(i, Traj_index);

Pin_result(i, Traj_index) = (10 * log10(get_RF_power(ChannelsObj, MeasObj)) + 30)+ Amp_in_loss;
Pin_lin(i, Traj_index) = 10^((Pin_result(i, Traj_index) - 30)/10);
Pout_lin(i, Traj_index) = 10^((Pout_result(i,Traj_index)- 30) / 10);
PAE(i, Traj_index) = ((Pout_lin(i, Traj_index) - Pin_lin(i, Traj_index))/ P_dc) * 100;

Traj_index = Traj_index+1;
end
end



end

save('STD_1_4MHz_QPSK_Load_Mod.mat')


close_GPIB();
%% Clean-up driver session
% if exist (deviceObj)
%     % Disconnect device object from hardware.
%     disconnect(deviceObj);
%     % Delete object
%     delete(deviceObj);
% end
