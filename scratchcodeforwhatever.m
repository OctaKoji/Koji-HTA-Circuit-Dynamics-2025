
%% Import Converted_headFB;Tone from NE

force = Converted_headFB(:,1); % get continuous force 
time = Converted_headFB(:,2); % get time stamps of the force

smoothedForce = smoothdata(force,'gaussian',100); % smooth the force, determine the smooth level
smoothed_FB = [smoothedForce time];
%plot(time,smoothedForce)
%ylimits = ylim;

%
stdVec = [];
sampleVec = [1:25:length(time)]'; % 10ms resolution, number of time devided by 100

for i = 2:length(sampleVec) % calculate the standard devitaion and assign it to stdVec
    stdVec(i,1) = std(smoothedForce(sampleVec(i-1):sampleVec(i)-1));
end

smoothedStd = smoothdata(stdVec,'gaussian',4); % determine the smooth level

% figure
% plot(sampleVec,smoothedStd)

% if the std passed the threshold, the value of the bin will be 1; otherwise it will be 0 
digitalStd = [];
for i = 1:length(smoothedStd)
    if smoothedStd(i) >= 3
        digitalStd(i,1) = 1;
    else
        digitalStd(i,1) = 0;
    end
end

% 
forceTracker = 0;
points = 0;

if digitalStd(1)
   tracker = 1;
   points = 1;
   count = 1;
else
   tracker = 0; % use to compare two consequctive values
   count = 0; % record the start and end of time
end

for i = 2:length(digitalStd)
    if tracker 
        if digitalStd(i)-digitalStd(i-1) ~= 0
            points(count,2) = i-1;
            tracker = 0;
        end
    else
        if digitalStd(i)-digitalStd(i-1) ~= 0
            count = count + 1;
            points(count,1) = i;
            tracker = 1;
        end
    end
end
% 
 %combine the movements if they happen too shortly
 combinedPoints = [];
 counter = 1;
 combinedPoints(counter,:) = points(counter,:);
 for i = 2:size(points,1)    
     if points(i,1)-points(i-1,2) < 0.0001
       combinedPoints(counter,2) = points(i,2);
     else
       counter = counter + 1;
       combinedPoints(counter,:) = points(i,:);
     end
 end

%filter by duration, remove jerky movements
numoflongmovement = 0;
pointsBig = [];
pointsBig2 = []; % timestamp of movement with high duration
for i = 1:length(combinedPoints(:,1))
    if time(sampleVec(combinedPoints(i,2))) - time(sampleVec(combinedPoints(i,1))) > 0.1 %&& %combinedPoints(i,2) - combinedPoints(i,1) < 100
        numoflongmovement = numoflongmovement + 1;
        pointsBig = cat(2,combinedPoints(i,1),combinedPoints(i,2));
        pointsBig2 = [pointsBig2;pointsBig];
    end
end

% Visualization
figure
plot(time,smoothedForce)
hold on
ylimits = ylim;
x1 = time(sampleVec(pointsBig2(:,1))); %start of movement 
x2 = time(sampleVec(pointsBig2(:,2))); %end of movements
fill([x1 x2 x2 x1],[ylimits(1) ylimits(1) ylimits(2) ylimits(2)],'red','FaceAlpha',0.3)
% xline(time(sampleVec(pointsBig2(:,1))),'r','LineWidth', 1)
% xline(time(sampleVec(pointsBig2(:,2))),'g','LineWidth', 1)
% for i = 1:length(Tone)
%     xline(Tone(i),'c','LineWidth', 2)
% end
hold off

 startofmoveshort = time(sampleVec(pointsBig2(:,1)));
 endofmoveshort = time(sampleVec(pointsBig2(:,2)));
 
 %% 
 %% no lick task:
% startIdx = sampleVec(pointsBig2(:,1));
% endIdx = sampleVec(pointsBig2(:,2));
idx_m = [startIdx endIdx];
Amplitude = [];
delete = [];
for i = 1:size(idx_m,1)
    if idx_m(i,1) > 1 && idx_m(i,2) < length(smoothedForce)
        ForceAmp = mean(smoothedForce(idx_m(i,1):idx_m(i,2))) - min(smoothedForce(idx_m(i,1)-1),smoothedForce(idx_m(i,2)+1));
        Amplitude = [Amplitude;ForceAmp];
        if ForceAmp < 20 && ForceAmp > -20                                  % Change
            delete = [delete i];
        end
    end
end
idx_m(delete,:) = [];
moveStart = time(idx_m(:,1));
moveEnd = time(idx_m(:,2));
figure()
plot(time,smoothedForce)
hold on
ylimits = ylim;
x1 = time(idx_m(:,1));
x2 = time(idx_m(:,2));
fill([x1 x2 x2 x1],[ylimits(1) ylimits(1) ylimits(2) ylimits(2)],'red','FaceAlpha',0.3)
for i = 1:length(Reward)
    xline(Reward(i), 'c', 'LineWidth', 2)
end
hold off
%% add intervals
DataIndex3 = [cursor_info3.DataIndex].';
DataIndex3 = sort(DataIndex3);
idx_m = [sort([idx_m(:,1); DataIndex3(1:2:end)]) sort([idx_m(:,2); DataIndex3(2:2:end)])];

% delete intervals
DataIndex4 = [cursor_info4.DataIndex].';
delete = zeros(length(DataIndex4),1);
for i = 1:length(delete)
    delete(i) = find(idx_m(:,1)<DataIndex4(i),1,'last');
end
idx_m(delete,:) = [];

%run after either
moveStart = time(idx_m(:,1));
moveEnd = time(idx_m(:,2));

% Alternative
% moveStart = sort([Move_Lick_noReward_StartTimes; RewardTriggering_Move_StartTimes; transitionStartTimesForward]);
% moveEnd = sort([Move_Lick_noReward_EndTimes; RewardTriggering_Move_EndTimes; transitionEndTimesForward]);
% moveStartBack = sort([Move_Lick_noReward_StartTimes_Back; transitionStartTimesBackward]);
% moveEndBack = sort([Move_Lick_noReward_EndTimes_Back; transitionEndTimesBackward]);

%% Separate different movements
idx_reward = zeros(length(Reward),1);
for i = 1:length(Reward)
    temp = find(moveStart < Reward(i));
    idx_reward(i) = temp(end);
end
idx_reward = unique(idx_reward);
idx_auto = setdiff(1:length(moveStart),idx_reward);
temp1 = (moveStart <= Licks.') & (moveEnd > Licks.');
idx_lick = find(any(temp1, 2));
idx_nolick = setdiff(idx_auto,idx_lick);
idx_lick = setdiff(idx_auto,idx_nolick);
Movestart_Reward = moveStart(idx_reward);
Moveend_Reward = moveEnd(idx_reward);
Movestart_lick = moveStart(idx_lick);
Moveend_lick = moveEnd(idx_lick);
Movestart_noLick = moveStart(idx_nolick);
Moveend_noLick = moveEnd(idx_nolick);

%% Test Variable
idx_noreward = setdiff(idx_auto,idx_reward);
Movestart_noreward = moveStart(idx_noreward);
Moveend_noreward = moveEnd(idx_noreward);

%% Sort movements based on amplitude
fps = 1000;
%Data = AVConvHeadFBStartofMove;
Data = Converted_headFB;
Event = startofmovenoreward; %Movestart_lick_Rewardfiltered1500ms;
t = 0.5;
Idx_Event = zeros(length(Event),1);
for i = 1 : length(Event)
    Idx_Event(i) = find(abs(Data(:,2)-Event(i))<0.0001);
end
delete = find(Idx_Event == 0);
Idx_Event(delete) = [];
Amp = [];
for i = 1:length(Idx_Event)
    NegativeAmp = min(Data(Idx_Event(i):Idx_Event(i)+fps*t,1));
    PositiveAmp = max(Data(Idx_Event(i):Idx_Event(i)+fps*t,1));
    if PositiveAmp-Data(Idx_Event(i)) > Data(Idx_Event(i))-NegativeAmp
        Amp = [Amp; PositiveAmp];
    else
        Amp = [Amp; NegativeAmp];
    end
end
[sortedAmp, sortindices] = sort(Amp);
sortedIdx_Event = Idx_Event(sortindices,:);
Order = zeros(length(sortedIdx_Event),1);
for i = 1:length(sortedIdx_Event)
    Order(i) = Data(sortedIdx_Event(i),2) + i*min(diff(Event))/(length(sortedIdx_Event)+1);
end
% Movestart_lick_backward = Data(sortedIdx_Event(1:30),2);
% Movestart_lick_forward = Data(sortedIdx_Event(68:end),2);

%%
ForceAmp = [30 -30];
save('C:\Users\yinlab\Box\duke_yinlab\Feiyang\20240627Start\m70\20240706_m70\thres_-10_-30_-10\cursor_info.mat', 'cursor_info','cursor_info1','cursor_info3','MovementDetection_StdThres', 'MovementCombine_StdThres', 'MovementCombine_LickIntervalThres', 'ForceAmp')
% save('C:\Users\fh78\Box\duke_yinlab\Feiyang\20240627Start\m67\20240627_m67\300msDelay_good\cursor_info.mat', 'cursor_info', 'cursor_info1', 'cursor_info2', 'MovementDetection_StdThres', 'MovementCombine_StdThres', 'MovementCombine_LickIntervalThres', 'Amp', 'Amplitude', 'ForceAmp')
% save('C:\Users\yinlab\Box\duke_yinlab\Feiyang\20240627Start\m72\20240630_m72\temp.mat', 'cursor_info', 'MovementDetection_StdThres', 'MovementCombine_StdThres', 'MovementCombine_LickIntervalThres')

%% Generating AbsValForce Derivative
smoothed_FB = smoothdata(AVConvHeadFBStartofMove(:,1),'gaussian',100);
dForce = [AVConvHeadFBStartofMove(1,1); diff(smoothed_FB)];
dForce = [dForce AVConvHeadFBStartofMove(:,2)];

dForce = [-dForce(:,1) dForce(:,2)];

%% Integral of signal Tone comparison

% Ensure time and signal are sorted
[RightChannelTime, sortIdx] = sort(RightChannel(:, 2));
RightChannelSignal = RightChannel(sortIdx, 1);

% Function to compute the integral for given bounds
computeIntegral = @(lowerBound, upperBound) trapz(RightChannelTime(RightChannelTime >= lowerBound & RightChannelTime <= upperBound), ...
                                                     RightChannelSignal(RightChannelTime >= lowerBound & RightChannelTime <= upperBound));

% Compute integrals for Tone05s4
integrals_Tone05s4 = zeros(length(Tone05s4), 1);
for i = 1:length(Tone05s4)
    % Find the next Tone timestamp after the current Tone05s4 timestamp
    nextToneIdx = find(Tone > Tone05s4(i), 1);
    if ~isempty(nextToneIdx)
        upperBound = Tone(nextToneIdx);
        lowerBound = Tone05s4(i);
        integrals_Tone05s4(i) = computeIntegral(lowerBound, upperBound);
    end
end

% Average of the integrals for Tone05s4
integral_Tone05s4 = mean(integrals_Tone05s4);

% Compute integrals for Tone1s4
integrals_Tone1s4 = zeros(length(Tone1s4), 1);
for i = 1:length(Tone1s4)
    % Find the next Tone timestamp after the current Tone1s4 timestamp
    nextToneIdx = find(Tone > Tone1s4(i), 1);
    if ~isempty(nextToneIdx)
        upperBound = Tone(nextToneIdx);
        lowerBound = Tone1s4(i);
        integrals_Tone1s4(i) = computeIntegral(lowerBound, upperBound);
    end
end

% Average of the integrals for Tone1s4
integral_Tone1s4 = mean(integrals_Tone1s4);

%% grouping reward bursts

% Initialize variables
groups = {}; % Cell array to hold the groups
currentGroup = Reward(1); % Start with the first timestamp in the first group

% Iterate through the timestamps
for i = 2:length(Reward)
    % Check if the current timestamp is within 5 seconds of the last timestamp in the current group
    if Reward(i) - Reward(i-1) < 2
        % Add the timestamp to the current group
        currentGroup = [currentGroup; Reward(i)];
    else
        % End of the current group; store it and start a new group
        groups{end+1} = currentGroup;
        currentGroup = Reward(i);
    end
end

% Add the last group to the list
groups{end+1} = currentGroup;

% Extract the first timestamp from each group
First = cellfun(@(x) x(1), groups);
First = First(:);

%% Sufficient Bursts
SBurst = []; % Initialize the new variable for storing bursts

% Loop through each timestamp in First
for i = 1:length(First)
    % Define the time interval (5 seconds after the current First timestamp)
    startTime = First(i);
    endTime = startTime + 10; % 5 seconds later
    
    % Count the number of licks within this interval
    countLicks = sum(Licks >= startTime & Licks < endTime);
    
    % Check if the count is greater than or equal to 20
    if countLicks >= 60
        % If so, add the current First timestamp to SBurst
        SBurst = [SBurst; startTime]; % Append to SBurst
    end
end

%% scratch data manipulation
ainp = variable
ainp(:,1) = (ainp(:,1) * (-1)) + 1000;
%% finding min values in extracted data

min_data1 = min(data1)';