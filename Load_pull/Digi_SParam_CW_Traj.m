%close all;
load('S11_STD')
load('S11_DPS')


set(0, 'DefaultAxesFontName', 'Arial')
set(0, 'DefaultUIControlFontName', 'Arial')

% connecting PNAX
PNAX = acquire_PNAX();
initialise_PNAX(PNAX);
load_PNAX_cal(PNAX, 'JB800', 1);
% set measurement channel
setup_PNAX_measurement(PNAX, 1, 'CH1_S11_2', 'S11')
% set sweep frequencys and measurement points
setup_PNAX_sweepfreqs(PNAX, 0, 881e6, 881e6, 0) 



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FTD2XX_SPI_libMPSSE.m
%    Test file to get a SPI port on an FTDI chip up and running, including:
%       1. Calling FTDI SPI library libMPSSE.dll from Matlab
%		2. Connecting to, configuring, and writing to a SPI channel
%      
%	How to get the library:
%		Visit http://www.ftdichip.com/Support/SoftwareExamples/MPSSE/LibMPSSE-SPI.htm
%		Download and open LibMPSSE-SPI.zip
%		Copy LibMPSSE-SPI\Release\lib\windows\x64\libMPSSE.dll into the folder containing this file
%		Or, if using 32-bit windows, LibMPSSE-SPI\Release\lib\windows\i386\libMPSSE.dll (NOT TESTED!)
%		You don't need any of the other files in the zip file, and the .h file provided is used in place of the one from
%		the zip file.

%    Notes:
%		This uses the MPSSE SPI library, originally downloaded from 
%			http://www.ftdichip.com/Support/SoftwareExamples/MPSSE/LibMPSSE-SPI.htm
%		Loading the library as-is fails, apparently because MATLAB is attempting to recursively include all the .h
%			files included by the driver, including built-in files.  For whatever reason, it fails to find them.
%		This code was tested on a 64-bit windows 7 machine, with an FT232H chip
%
%		See AN_178_User Guide for LibMPSSE-SPI.pdf for detailed information on functions.	
%
%		If SPI_Write and SPI_CloseChannel are returning 18, try unplugging/replugging the USB cable.
%   
% Author: Eric Pahlke, Oct 22, 2014
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Return value error codes
% 	0	FT_OK,
% 	1	FT_INVALID_HANDLE,
% 	2	FT_DEVICE_NOT_FOUND,
% 	3	FT_DEVICE_NOT_OPENED,
% 	4	FT_IO_ERROR,
% 	5	FT_INSUFFICIENT_RESOURCES,
% 	6	FT_INVALID_PARAMETER,
% 	7	FT_INVALID_BAUD_RATE,	 
% 	8	FT_DEVICE_NOT_OPENED_FOR_ERASE,
% 	9	FT_DEVICE_NOT_OPENED_FOR_WRITE,
% 	10	FT_FAILED_TO_WRITE_DEVICE,
% 	11	FT_EEPROM_READ_FAILED,
% 	12	FT_EEPROM_WRITE_FAILED,
% 	13	FT_EEPROM_ERASE_FAILED,
% 	14	FT_EEPROM_NOT_PRESENT,
% 	15	FT_EEPROM_NOT_PROGRAMMED,
% 	16	FT_INVALID_ARGS,
% 	17	FT_NOT_SUPPORTED,
% 	18	FT_OTHER_ERROR

% Libname matches the name of the .dll
Libname = 'libMPSSE';

% "Don't call loadlibrary if the library is already loaded into memory" (loadlibrary help)
% The second argument is the header file containing the list of functions from Libname
% Note that it's ONLY used for the list of functions.  Therefore, any #include statements should be
% removed, and any typedefs used in the function declarations must be typedef'd inside the h file.
% Because the library is already compiled in the dll, the #include statements are extraneous, and cause
% loadlibrary to fail as it attempts to preprocess the header file.
if ~libisloaded( Libname )
	loadlibrary( Libname, 'libMPSSE_spi_matlabFriendly.h');
end

% Quick view of other library functions
% libfunctionsview(Libname)

% This shouldn't be required.
% calllib(Libname,'Init_libMPSSE');

% This is how we define a pointer in matlab.  Required to match the parameter types in various functions.
pNumchannels = libpointer('uint32Ptr',255);
pNumBytesTransferred = libpointer('uint32Ptr',255);

pChannelHandle0 = libpointer('voidPtr',255);
pChannelHandle1 = libpointer('voidPtr',255);

% Get the number of SPI channels available.  If 1, we can talk to an FTDI chip.  If 0... not so much
calllib(Libname,'SPI_GetNumChannels',pNumchannels); pause(0.1);
sprintf('Channels Found: %d',get(pNumchannels,'value'))
% Should find 2 channels, prob do some error checking for this


% Connect to SPI channel 0.  Valid numbers are 0:(Numchannels-1).
Status0 = calllib(Libname,'SPI_OpenChannel',0,pChannelHandle0); 
pause(0.1);

Status1 = calllib(Libname,'SPI_OpenChannel',1,pChannelHandle1); 
pause(0.1);

if Status0 + Status1 == 0
    disp('Channels opened successfully')
else
   disp('Error opening channels')
   return;
end

% Define the channel configuration struct, and initialize the channel.
ChConfig.ClockRate = uint32(10e6); % Clock speed, Hz
ChConfig.LatencyTimer = uint8(2); % Users guide section 3.4, suggested value is 2-255 for all devices
ChConfig.configOptions = uint32(0); % Bit 1 is CPOL, bit 0 is CPHA.  Higher order bits configure the chip select.

Status0 = calllib(Libname,'SPI_InitChannel',pChannelHandle0,ChConfig);
pause(0.1);

Status1 = calllib(Libname,'SPI_InitChannel',pChannelHandle1,ChConfig);
pause(0.1);

if Status0 + Status1 == 0
    disp('Channels initialised successfully')
else
   disp('Error initialising channels')
   return;
end




transfer_options = 6; % Chip select used.

%Each DTC has a 5 bit register with states 0-31, proportional to Cs
figure(1)
smithchart
hold on
plot(real(S11_Std),imag(S11_Std),'or','LineWidth',4)
plot(real(S11_DPS),imag(S11_DPS),'ob','LineWidth',4)
title('CW Optimum Trajectories')
legend('STD','DPS') 

S11 = zeros(32,32);

for a = 0:31
    %Outer loop for serial capacitor
    % Alter write buffer and channel handle
    writebuffer = a;
    calllib(Libname,'SPI_Write',pChannelHandle0,writebuffer,length(writebuffer),pNumBytesTransferred,transfer_options);
    
    
    
   for b = 0:31
       % Inner loop for parallel capacitor
       % Alter write buffer and channel handle
       writebuffer = b;
       calllib(Libname,'SPI_Write',pChannelHandle1,writebuffer,length(writebuffer),pNumBytesTransferred,transfer_options);
       
       Cs = (0.394*a) + 1.456; 
       Cp = (0.394*b) + 1.456;
       Cs_string = sprintf('Cs: %.4f pF',Cs);
       Cp_string = sprintf('Cp: %.4f pF',Cp);
       disp(Cs_string)
       disp(Cp_string)
       
       pause(0.1)
       %Get VNA results here
       query(PNAX, '*OPC?', '%s\n', '%d');
       data = read_S11_measurement(PNAX, 1, 'CH1_S11_1');
       fread(PNAX,1);
       S11(a+1,b+1) = data(1,2) + 1i*data(1,3);
       plot(real(S11(a+1,b+1)),imag(S11(a+1,b+1)),'.g','LineWidth',4)
       
       
   end
end





% Clean up
calllib(Libname,'SPI_CloseChannel',pChannelHandle0);
calllib(Libname,'SPI_CloseChannel',pChannelHandle1);
return 





% set(gca,'fontsize',14)
% print('-dpng', '-r600', 'CW_Traj_orig.png');
% set(gcf, 'PaperPosition', [0 0 16 11]); %Position plot at left hand corner with width 5 and height 5.
% set(gcf, 'PaperSize', [16 11]); %Set the paper to have width 5 and height 5.
% filename = 'CW_Traj_orig.pdf';
% saveas(gcf, filename); %Save figure