%% data import
ainp9 = laserTTL; % ainp7 or ainp9 edit
addpath('C:\Users\yinlab\Box\duke_yinlab\Koji\Feiyanggavemescripts')
%edited
blkrck = getAnalogTimestampsBlackrock(ainp9(:,1),ainp9(:,2),3000);
eventsBR = blkrck(:,2); % ni box signal on Blackrock
%C:\Users\qj21\Box\duke_yinlab\Koji\VTA Glutamate\
xlsFileName = uipickfiles('FilterSpec','C:\Users\yinlab\Box\duke_yinlab\Koji\FreeBox\VGlut2-55\Vglut2-55-M5_0.3pOmission_032025\2025_03_20-14_05_13');
[events,~] = xlsread(xlsFileName{2}); 
eventsRwd = events(events(:,3) == 0,1); 
eventsRwd = eventsRwd./1000; % ni box signal on RWD

[data,varNames] = xlsread(xlsFileName{1});
initTimestamp = data(:,1)./1000;

% % Fitting timestamp
% startloc = find(initTimestamp - eventsRwd(1) < 0, 1, 'last');
% stoploc = find(initTimestamp - eventsRwd(end) < 0, 1, 'last');
% FiberphotometryTimestamps = nan(numel(initTimestamp), 1);
% FiberphotometryTimestamps(startloc:stoploc) = linspace(eventsBR(1), eventsBR(end), stoploc - startloc + 1);

signalTimestamp = zeros(size(initTimestamp));
if length(eventsBR) < length(eventsRwd)
    eventsRwd(length(eventsBR)+1:end) = [];
    disp('eventsBR ≠ eventsRWD');
%KojiEditPortion
elseif length(eventsBR) > length(eventsRwd)
    eventsBR(1:length(eventsBR)-length(eventsRwd)) = [];
end
tic
for i = 1:length(initTimestamp)
    thisTrace = initTimestamp(i) - eventsRwd;
    [~,loc] = min(thisTrace(thisTrace>0));
    if isempty(loc)
        signalTimestamp(i) = nan;
    else
        signalTimestamp(i) = eventsBR(loc) + ( initTimestamp(i) - eventsRwd(loc) );
    end
end
toc

%
if sum(diff(signalTimestamp)<0) ~= 0
    signalTimestamp(~isnan(signalTimestamp)) = sort(signalTimestamp(~isnan(signalTimestamp)));
end

FiberphotometryTimestamps = signalTimestamp;


%% Extract Flouroscence data 
CH1_410Column = strcmp(varNames,'CH1-410') == 1;
CH2_410Column = strcmp(varNames,'CH2-410') == 1; 
CH1_470Column = strcmp(varNames,'CH1-470') == 1;
%CH1_560Column = strcmp(varNames,'CH1-560') == 1;
CH2_470Column = strcmp(varNames,'CH2-470') == 1;
%CH2_560Column = strcmp(varNames,'CH2-560') == 1;

CH1_410 = data(:,3);
 CH2_410 = data(:,5);
CH1_470 = data(:,4);
%CH1_560 = data(:,CH1_560Column);
 CH2_470 = data(:,6);
%CH2_560 = data(:,CH2_560Column);

% clearvars -except CH1_410 CH2_410 CH1_470 CH1_560 CH2_470 CH2_560 Converted_headFB Converted_headSS Converted_headUD FiberphotometryTimestamps Tone Licks Reward


%% Motion Correction for Green Fluorescence
Motionfitted_CH1_410 = predict(fitlm(CH1_410, CH1_470, 'Robust', 'on'), CH1_410);
%MotionCorrected_CH1_470 = CH1_470 - Motionfitted_CH1_410;
Motionfitted_CH2_410 = predict(fitlm(CH2_410, CH2_470, 'Robust', 'on'), CH2_410);
%MotionCorrected_CH2_470 = CH2_470 - Motionfitted_CH2_410;

MotionCorrected_CH1_470 = 100*(CH1_470-Motionfitted_CH1_410)./Motionfitted_CH1_410;
%Motionfitted_CH2_410 = predict(fitlm(CH2_410, CH2_470, 'Robust', 'on'), CH2_410);
MotionCorrected_CH2_470 = 100*(CH2_470-Motionfitted_CH2_410)./Motionfitted_CH2_410;
% Smoothing
Smoothed_MotionCorrected_CH1_470 = smoothdata(MotionCorrected_CH1_470, 'gaussian', 5);
Smoothed_MotionCorrected_CH2_470 = smoothdata(MotionCorrected_CH2_470, 'gaussian', 5);
LeftChan = [Smoothed_MotionCorrected_CH1_470 FiberphotometryTimestamps];
RightChan = [Smoothed_MotionCorrected_CH2_470 FiberphotometryTimestamps];
LeftChannel = LeftChan(~any(isnan(LeftChan), 2), :);
RightChannel = RightChan(~any(isnan(RightChan), 2), :);





%% single
Motionfitted_CH1_410 = predict(fitlm(CH1_410, CH1_470, 'Robust', 'on'), CH1_410);
%MotionCorrected_CH1_470 = CH1_470 - Motionfitted_CH1_410;
%MotionCorrected_CH2_470 = CH2_470 - Motionfitted_CH2_410;

MotionCorrected_CH1_470 = 100*(CH1_470-Motionfitted_CH1_410)./Motionfitted_CH1_410;
%Motionfitted_CH2_410 = predict(fitlm(CH2_410, CH2_470, 'Robust', 'on'), CH2_410);
% Smoothing
Smoothed_MotionCorrected_CH1_470 = smoothdata(MotionCorrected_CH1_470, 'gaussian', 5);
LeftChan = [Smoothed_MotionCorrected_CH1_470 FiberphotometryTimestamps];
LeftChannel = LeftChan(~any(isnan(LeftChan), 2), :);

%%

% %% Motion Correction for Red Fluorescence
% Motionfitted_CH1_470 = predict(fitlm(CH1_470, CH1_560, 'Robust', 'on'), CH1_470);
% Motionfitted_CH2_470 = predict(fitlm(CH2_470, CH2_560, 'Robust', 'on'), CH2_470);
% 
% MotionCorrected_CH1_560 = (CH1_560-Motionfitted_CH1_470)./Motionfitted_CH1_470;
% MotionCorrected_CH2_560 = (CH2_560-Motionfitted_CH2_470)./Motionfitted_CH2_470;
% 
% 
% % Smoothing
% Smoothed_MotionCorrected_CH1_560 = smoothdata(MotionCorrected_CH1_560, 'gaussian', 5);
% Smoothed_MotionCorrected_CH2_560 = smoothdata(MotionCorrected_CH2_560, 'gaussian', 5);
% 
% visualization
l = length(Smoothed_MotionCorrected_CH1_560);
figure()
plot(1:l,CH2_560)
hold on
plot(1:l,Motionfitted_CH2_470)
plot(1:l,zscore(Smoothed_MotionCorrected_CH2_560))
% plot(1:l,zscore(MotionCorrected_CH1_560))
legend('rawsignal','fittedcontrol','signal')
title('RightChan');
hold off

% LeftChan = [Smoothed_MotionCorrected_CH1_560 FiberphotometryTimestamps];
% RightChan = [Smoothed_MotionCorrected_CH2_560 FiberphotometryTimestamps];
% 
% LeftChannel = LeftChan(~any(isnan(LeftChan), 2), :);
% RightChannel = RightChan(~any(isnan(RightChan), 2), :);
% 
% clearvars -except LeftChannel RightChannel Converted_headFB Converted_headSS Converted_headUD Tone Licks Reward cursor_info ainp11
% figure
% %plot(RightChannel(:,2),RightChannel(:,1)*1.7+0.3)
% %hold on
% plot(LeftChannel(:,2),LeftChannel(:,1))
% legend('Right','Left')
% hold off