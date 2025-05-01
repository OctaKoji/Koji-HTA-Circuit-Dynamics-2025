%% Generate trial-by-trial perievent data

T0 = -8;
Tf = 20;
% fps = 30; %add an if vara or varb loop to choose fps
% fps = 1000;

 Data = LHt_VGluT;
%  RightChannel = VTA;
% Data = mPFC;
%  Data = RightChannel;
% Data = LeftChannel;
% Converted_headFB = AVConvHeadFBStartofMove;
% RightChannel = LHT_VGluT
% Data = RightChannel  
%Data = Licks;
% Data = dForce;
% Data = lickForce;

Event = Airpuff;
% Event = [Tonerrrr;Tonewwww];
% Event = [Tone1s;Tone2s];
% Event = FirstLickAfterReward;
%Event = Airpuffnoreward
% Event = Tone_Rewarded;
%  Event = Tone_RewardOmitted
% Event = [Tone_Rewarded;Tone_RewardOmitted];
% Event = Tone;
%Event = FirstLickAfterTest;

%if abs(Data(1,1) - lickForce(1,1)) < 0.01
   % fps = 1000;
   % Data(:,1) = smoothdata(Data(:,1),'gaussian',10);
%elseif abs(Data(1,1) - Converted_headFB(1,1)) < 0.01
   % fps = 1000; %changed
   % Data(:,1) = smoothdata(Data(:,1),'gaussian',100);
  %  dForce = [Converted_headFB(1,1); diff(Data(:,1))];
   % dForce = [dForce Converted_headFB(:,2)];
%elseif abs(Data(1,1) - RightChannel(1,1)) < 0.01 || abs(Data(1,1) - LeftChannel(1,1)) < 0.01
    fps = 30;
    Data(:,1) = Data(:,1) * 100;
%elseif abs(Data(1,1) - LickHzSession(1,1)) < 0.01
   % fps = 1000;
%elseif abs(Data(1,1) - dForce(1,1)) < 0.01
 %   fps = 1000;
%end

% fps = 30

Idx_Event = zeros(length(Event),1);
for i = 1 : length(Event)
    if Event(i) < Data(end,2) && Event(i) > Data(1,2)
        Idx_Event(i) = find(Data(:,2)>Event(i),1);
    end
end
delete = find(Idx_Event == 0);
Idx_Event(delete) = [];
SigEvent = [];
for i = 1:length(Idx_Event)
    if Idx_Event(i)+T0*fps+1 > 0 && Idx_Event(i)+Tf*fps <= size(Data,1)
        SigEvent = [SigEvent Data(Idx_Event(i)+T0*fps+1:Idx_Event(i)+Tf*fps,1)];
    else
        SigEvent = [SigEvent zeros(size(SigEvent,1),1)];
    end
end

%  SigEvent = SigEvent * 100; %add an if loop on this eventually
% SigEvent = -SigEvent;


% ZscoreSig = normalize(SigEvent);

% Z-score
% bl0 = -0.5;
% blf = -0.2;
% bl0 = -2;
% blf = -1.5;
bl0 = -7.99;
blf = -7.75;
zscoreoverbaselineSig = zeros(size(SigEvent));
for i = 1:size(SigEvent,2)
    miu = mean(SigEvent(round(fps*(bl0-T0))+1:round(fps*(blf-T0)),i));
    sigma = std(SigEvent(round(fps*(bl0-T0))+1:round(fps*(blf-T0)),i));
    zscoreoverbaselineSig(:,i) = (SigEvent(:,i)-miu)/sigma;
end

% X Axis
XTime = (T0:(Tf-T0)/(size(zscoreoverbaselineSig,1)-1):Tf)';

%(lickforce) normalizing
temp = SigEvent(:);
temp = normalize(temp);
ZscoreSig = reshape(temp, size(SigEvent,1), size(SigEvent,2));

%normalize for comparison of diff sig
zscore = normalize(zscoreoverbaselineSig);

% data1 = zscore;
data1 = zscoreoverbaselineSig;
%  data1 = zscoreoverbaselineSig;

writematrix(data1, 'C:\Users\yinlab\Desktop\data1.csv')
%% Raster Plot
image(SigEvent')

%% LickHz

% Calculate the time differences between consecutive licks
timeDiffs = diff(Licks); % This gives you the time differences in seconds

% Calculate the frequency in Hz (licks per second)
% The frequency is 1 / time difference, and the first element will be NaN
LickFrequency = [NaN; 1 ./ timeDiffs]; % Add NaN for the first lick as it has no previous lick

% Create the new variable LickHz
LickHz = [LickFrequency, Licks(:)]; % Ensure Licks is a column vector

time = laserTTL(:,2) %use whatever gives you time from continuous variables. Use blackbox values not PF for alignment's sake

% Interpolating the frequencies to match the 'time' timestamps
% Use 'pchip' for piecewise cubic Hermite interpolating polynomial
LickHzValues = interp1(Licks, LickFrequency, time, 'pchip', 0);

% Create LickHzSession variable
LickHzSession = [LickHzValues, time(:)]; % Ensure time is a column vector

%%
sorted_LHT_Lick = sortrows(LHT_Lick, 1);

%% first/last min norm over z score sig
% Assuming zscoreoverbaselineSig, T0, Tf, fps, Idx_Event, etc. are already defined
% Define number of events to consider
nEvents = 5;
% Initialize vectors
first5min = zeros(nEvents,1);
last5min = zeros(nEvents,1);
% First 5 events
for i = 1:nEvents
    if i <= size(zscoreoverbaselineSig,2)
        this_trace = zscoreoverbaselineSig(:,i);
        first5min(i) = min(this_trace);
    else
        first5min(i) = NaN; % In case there are fewer than 5 events
    end
end
% Last 5 events
for i = 1:nEvents
    idx = size(zscoreoverbaselineSig,2) - nEvents + i;
    if idx > 0
        this_trace = zscoreoverbaselineSig(:,idx);
        last5min(i) = min(this_trace);
    else
        last5min(i) = NaN; % In case there are fewer than 5 events
    end
end

%% test and plot
% Assume first5min and last5min already exist
% 1. Filter out NaNs
first5min_valid = first5min(~isnan(first5min));
last5min_valid = last5min(~isnan(last5min));
% 2. Perform Mann-Whitney U test (unpaired, nonparametric)
[p, h, stats] = ranksum(first5min_valid, last5min_valid);
% 3. Plot as two groups
figure;
hold on;
% Plot individual points (jittered for visibility)
scatter(ones(size(first5min_valid)) + randn(size(first5min_valid))*0.05, first5min_valid, 'filled', 'MarkerFaceAlpha', 0.6);
scatter(2*ones(size(last5min_valid)) + randn(size(last5min_valid))*0.05, last5min_valid, 'filled', 'MarkerFaceAlpha', 0.6);
% Plot means
plot(1, mean(first5min_valid), 'ks', 'MarkerFaceColor', 'k', 'MarkerSize', 10);
plot(2, mean(last5min_valid), 'ks', 'MarkerFaceColor', 'k', 'MarkerSize', 10);
% Format plot
xlim([0.5 2.5]);
xticks([1 2]);
xticklabels({'First 5 Events', 'Last 5 Events'});
ylabel('Minimum Z-Score over Baseline');
title(['Unpaired Comparison (p = ' num2str(p, '%.3f') ')']);
hold off;
%% test v2 original test above better
% Assume first5min and last5min already exist
% 1. Filter out NaNs
first5min_valid = first5min(~isnan(first5min));
last5min_valid = last5min(~isnan(last5min));
% 2. Perform Mann-Whitney U test (unpaired, nonparametric)
[p, h, stats] = ranksum(first5min_valid, last5min_valid);
% 3. Calculate means and SEM
mean_first = mean(first5min_valid);
mean_last = mean(last5min_valid);
sem_first = std(first5min_valid) / sqrt(length(first5min_valid));
sem_last = std(last5min_valid) / sqrt(length(last5min_valid));
% 4. Plot
figure;
hold on;
% Scatter individual points (jittered for visibility)
scatter(ones(size(first5min_valid)) + randn(size(first5min_valid))*0.05, first5min_valid, 'filled', 'MarkerFaceAlpha', 0.6);
scatter(2*ones(size(last5min_valid)) + randn(size(last5min_valid))*0.05, last5min_valid, 'filled', 'MarkerFaceAlpha', 0.6);
% Plot mean points
plot(1, mean_first, 'ks', 'MarkerFaceColor', 'k', 'MarkerSize', 10);
plot(2, mean_last, 'ks', 'MarkerFaceColor', 'k', 'MarkerSize', 10);
% Add error bars (SEM)
errorbar(1, mean_first, sem_first, 'k', 'LineWidth', 1.5, 'CapSize',10);
errorbar(2, mean_last, sem_last, 'k', 'LineWidth', 1.5, 'CapSize',10);
% Format plot
xlim([0.5 2.5]);
xticks([1 2]);
xticklabels({'First 5 Events', 'Last 5 Events'});
ylabel('Minimum Z-Score over Baseline');
title(['Unpaired Comparison (p = ' num2str(p, '%.3f') ')']);
hold off;
%% Compare minimum signal values: Omitted vs Rewarded
% Each column = one trial, each row = signal at a time point
% 1. Extract minimum value from each trial
min_omitted = min(omitted, [], 1);
min_rewarded = min(rewarded, [], 1);
% 2. Filter out NaNs
min_omitted_valid = min_omitted(~isnan(min_omitted));
min_rewarded_valid = min_rewarded(~isnan(min_rewarded));
% 3. Perform Mann-Whitney U test
[p, h, stats] = ranksum(min_omitted_valid, min_rewarded_valid);
% 4. Plot the results
figure;
hold on;
% Plot individual points with jitter for clarity
scatter(ones(size(min_omitted_valid)) + randn(size(min_omitted_valid))*0.05, min_omitted_valid, ...
    'filled', 'MarkerFaceAlpha', 0.6, 'MarkerEdgeColor', 'none');
scatter(2*ones(size(min_rewarded_valid)) + randn(size(min_rewarded_valid))*0.05, min_rewarded_valid, ...
    'filled', 'MarkerFaceAlpha', 0.6, 'MarkerEdgeColor', 'none');
% Plot group means
plot(1, mean(min_omitted_valid), 'ks', 'MarkerFaceColor', 'k', 'MarkerSize', 10);
plot(2, mean(min_rewarded_valid), 'ks', 'MarkerFaceColor', 'k', 'MarkerSize', 10);
% Formatting
xlim([0.5 2.5]);
xticks([1 2]);
xticklabels({'Omitted', 'Rewarded'});
ylabel('Minimum Signal Value per Trial');
title(['Minimum Value Comparison (p = ' num2str(p, '%.3f') ')']);
hold off;
