ainp=Licks_analog;
Licks = getAnalogTimestampsBlackrock(ainp(:,1),ainp(:,2));

%% LickHz
% Initialize an array to store lick frequencies (LickHz) for each tone
LickHz = zeros(length(Tone), 1);

% Loop through each tone timestamp
for i = 1:length(Tone)
    % Get the current tone timestamp
    tone_time = Tone(i);
    
    % Find the licks that occur between tone_time and tone_time + 15 seconds
    licks_in_window = Licks(Licks >= tone_time & Licks <= tone_time + 15);
    
    % Count the number of licks in this time window
    num_licks = length(licks_in_window);
    
    % Calculate the lick frequency (Hz) for this trial
    % Lick rate = number of licks / 15 seconds
    LickHz(i) = num_licks / 15;
end

Avg = mean(LickHz)

%% grouping reward bursts

% Initialize variables
groups = {}; % Cell array to hold the groups
currentGroup = Reward(1); % Start with the first timestamp in the first group

% Iterate through the timestamps
for i = 2:length(Reward)
    % Check if the current timestamp is within x seconds of the last timestamp in the current group
    if Reward(i) - Reward(i-1) < 2 %update according to the threshold
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

%% Last Version
% Initialize variables
groups = {}; % Cell array to hold the groups
currentGroup = Reward(1); % Start with the first timestamp in the first group

% Iterate through the timestamps
for i = 2:length(Reward)
    % Check if the current timestamp is within x seconds of the last timestamp in the current group
    if Reward(i) - Reward(i-1) < 2 % Update according to the threshold
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

% Extract the first and last timestamps from each group
First = cellfun(@(x) x(1), groups);
First = First(:);
Last = cellfun(@(x) x(end), groups);
Last = Last(:);

%% Sufficient Bursts (Rewards)
SBurst = []; % Initialize the new variable for storing bursts

% Loop through each timestamp in First
for i = 1:length(First)
    % Define the time interval (5 seconds after the current First timestamp)
    startTime = First(i);
    endTime = startTime + 5; % 5 seconds later
    
    % Count the number of licks within this interval
    countLicks = sum(Licks >= startTime & Licks < endTime);
    
    % Check if the count is greater than or equal to 20
    if countLicks >= 25
        % If so, add the current First timestamp to SBurst
        SBurst = [SBurst; startTime]; % Append to SBurst
    end
end




%% Xth lick
% Define the ordinal number (e.g., 50, 70, etc.)
ordinalNumber = 50; % Change this as needed

% Ensure Reward is a column vector
Reward = Reward(:);

% Compute valid indices for LastInvol
lastIndices = ordinalNumber:ordinalNumber-2:length(Reward);

% Compute valid indices for FirstSpout (first timestamp after each LastInvol)
firstIndices = lastIndices + 1;
firstIndices = firstIndices(firstIndices <= length(Reward));

% Extract corresponding timestamps
LastInvol = Reward(lastIndices);
FirstSpout = Reward(firstIndices);


%% Inter-Lick-Interval
%Choose whether its an opto or not opto maybe. make those vars in NE first
% Define the length of SBurst (number of intervals)
numIntervals = length(First);

% Initialize a matrix to store the SBurst timestamps and corresponding average ISI
LicksISIintAvg = [];

% Loop through each SBurst and calculate the average inter-reward interval (LicksISIintAvg)
for i = 1:numIntervals-1
    % Define the interval based on the current SBurst
    start_time = First(i);
    end_time = (First(i+1) - 0.05);

    % Find the rewards within the interval
    rewards_in_interval = Reward(Reward >= start_time & Reward <= end_time);

    % Ensure there are at least two rewards to calculate the time differences
    if length(rewards_in_interval) > 1
        % Calculate the time differences between consecutive rewards
        time_differences = diff(rewards_in_interval);
        
        % Calculate the average of these time differences (LicksISIintAvg for this interval)
        avg_LicksISI = mean(time_differences);
        
        % Store the result in LicksISIintAvg (as a row with SBurst time and avg_LicksISI)
        LicksISIintAvg = [LicksISIintAvg; First(i), avg_LicksISI];  % Append to the result
    else
        % If there are fewer than two rewards, store NaN for this interval
        LicksISIintAvg = [LicksISIintAvg; First(i), NaN];
    end
end

% Display the result
disp('First timestamps and their corresponding average inter-reward intervals (LicksISIintAvg):');
disp(LicksISIintAvg);


%% Storage
directory = 'C:\Users\yinlab\Box\duke_yinlab\Koji\FreeBox\VGlut2-45\120324_OptoStim';  
filename = fullfile(directory, 'LicksISIintAvg.csv');
writematrix(LicksISIintAvg, filename);
disp(['Data saved to: ', filename]);

%% Splitting Data Based on LaserTTL TEST (Checks for both opto and not opto.)
% LOOKLOOKLOOKLOOK Be careful. This is kinda poorly written and updates
% First is a variable you'll use elsewhere so remember First will
% become FirstNotOpto by the end of it
% Set the directory where you want to save the data
directory = 'C:\Users\yinlab\Box\duke_yinlab\Koji\FreeBox\VGlut2-45\120324_OptoStim';  

% Process First_Opto
First = First_Opto;  % Assign First_Opto to First
numIntervals = length(First);

% Initialize the matrix to store the SBurst timestamps and average ISIs for First_Opto
LicksISIintAvg_Opto = [];

for i = 1:numIntervals-1
    start_time = First(i);
    end_time = (First(i+1) - 0.05);

    rewards_in_interval = Reward(Reward >= start_time & Reward <= end_time);

    if length(rewards_in_interval) > 1
        time_differences = diff(rewards_in_interval);
        avg_LicksISI = mean(time_differences);
        LicksISIintAvg_Opto = [LicksISIintAvg_Opto; First(i), avg_LicksISI];
    else
        LicksISIintAvg_Opto = [LicksISIintAvg_Opto; First(i), NaN];
    end
end

avgAllISIOpto = mean(LicksISIintAvg_Opto(:, 2));

% Save the results for First_Opto to a CSV
filename_Opto = fullfile(directory, 'LicksISIintAvg_Opto.csv');
writematrix(LicksISIintAvg_Opto, filename_Opto);
disp(['Data for First_Opto saved to: ', filename_Opto]);

% Process First_NoOpto
First = First_NotOpto;  % Assign First_NoOpto to First
numIntervals = length(First);

% Initialize the matrix to store the SBurst timestamps and average ISIs for First_NoOpto
LicksISIintAvg_NotOpto = [];

for i = 1:numIntervals-1
    start_time = First(i);
    end_time = (First(i+1) - 0.05);

    rewards_in_interval = Reward(Reward >= start_time & Reward <= end_time);

    if length(rewards_in_interval) > 1
        time_differences = diff(rewards_in_interval);
        avg_LicksISI = mean(time_differences);
        LicksISIintAvg_NotOpto = [LicksISIintAvg_NotOpto; First(i), avg_LicksISI];
    else
        LicksISIintAvg_NotOpto = [LicksISIintAvg_NotOpto; First(i), NaN];
    end
end

avgAllISINotOpto = mean(LicksISIintAvg_NotOpto(:, 2));

% Save the results for First_NoOpto to a CSV
filename_NotOpto = fullfile(directory, 'LicksISIintAvg_NotOpto.csv');
writematrix(LicksISIintAvg_NotOpto, filename_NotOpto);
disp(['Data for First_NotOpto saved to: ', filename_NotOpto]);
%% Generating Intervals for next code block
% Example variables (replace with actual data)
% LaserTTL_digin: Timestamps of LaserTTL_digin
% First_Lick_Reward: Timestamps of First Lick Rewards
% Reward: Timestamps of rewards
% Tone: Timestamps of Tone events

% Initialize the variables
First_RewardOpto = [];
First_RewardNotOpto = [];
Last_Reward_Reward = [];
Last_RewardOpto = [];
Last_RewardNotOpto = [];

% Step 1: Check if LaserTTL_digin is within 0.1s of First_Lick_Reward
for i = 1:length(LaserTTL_digin)
    % Find the First_Lick_Reward that is within 0.1 seconds of LaserTTL_digin(i)
    time_diff = abs(First_Lick_Reward - LaserTTL_digin(i));
    
    % If LaserTTL_digin is within 0.1s of First_Lick_Reward, add to First_RewardOpto
    if any(time_diff <= 0.1)
        % Add the corresponding First_Lick_Reward to First_RewardOpto
        First_RewardOpto = [First_RewardOpto; First_Lick_Reward(time_diff <= 0.1)];
    end
end

% Step 2: Define First_RewardNotOpto as all First_Lick_Reward timestamps not in First_RewardOpto
First_RewardNotOpto = setdiff(First_Lick_Reward, First_RewardOpto);

% Step 3: Find the last Reward before each Tone
for j = 1:length(Tone)
    % Find the Rewards that occurred before the current Tone[j]
    last_reward_idx = find(Reward < Tone(j), 1, 'last');
    
    % If a valid Reward was found, add it to Last_Reward_Reward
    if ~isempty(last_reward_idx)
        Last_Reward_Reward = [Last_Reward_Reward; Reward(last_reward_idx)];
    end
end

% Step 4: Ensure one-to-one mapping of First_RewardOpto and Last_RewardOpto
for k = 1:length(First_RewardOpto)
    % Find the last Reward that occurred within 15s after First_RewardOpto
    valid_rewards = Last_Reward_Reward(abs(Last_Reward_Reward - First_RewardOpto(k)) <= 15);
    
    % Ensure only one reward for each First_RewardOpto
    if ~isempty(valid_rewards)
        Last_RewardOpto = [Last_RewardOpto; valid_rewards(1)]; % Take only the first valid one
    end
end

% Step 5: Ensure one-to-one mapping of First_RewardNotOpto and Last_RewardNotOpto
for k = 1:length(First_RewardNotOpto)
    % Find the last Reward that occurred within 15s after First_RewardNotOpto
    valid_rewards = Last_Reward_Reward(abs(Last_Reward_Reward - First_RewardNotOpto(k)) <= 15);
    
    % Ensure only one reward for each First_RewardNotOpto
    if ~isempty(valid_rewards)
        Last_RewardNotOpto = [Last_RewardNotOpto; valid_rewards(1)]; % Take only the first valid one
    end
end

% Display the results
disp('First Reward Opto Timestamps:');
disp(First_RewardOpto);
disp('First Reward Not Opto Timestamps:');
disp(First_RewardNotOpto);
disp('Last Reward Timestamps:');
disp(Last_Reward_Reward);
disp('Last Reward Opto Timestamps:');
disp(Last_RewardOpto);
disp('Last Reward Not Opto Timestamps:');
disp(Last_RewardNotOpto);



%% Splitting Data Based on LaserTTL NON-BOUT
directory = 'C:\Users\yinlab\Box\duke_yinlab\Koji\FreeBox\Optogenetics\Vglut2-45\120324_OptoStim';  

% Process First_Opto
numIntervals = length(First_RewardOpto);

% Initialize the matrix to store the SBurst timestamps and average ISIs for First_Opto
LicksISIintAvg_Opto = [];

for i = 1:numIntervals-1
    start_time = First_RewardOpto(i);
    end_time = Last_RewardOpto(i);

    rewards_in_interval = Reward(Reward >= start_time & Reward <= end_time);

    if length(rewards_in_interval) > 1
        time_differences = diff(rewards_in_interval);
        avg_LicksISI = mean(time_differences);
        LicksISIintAvg_Opto = [LicksISIintAvg_Opto; First_RewardOpto(i), avg_LicksISI];
    else
        LicksISIintAvg_Opto = [LicksISIintAvg_Opto; First_RewardOpto(i), NaN];
    end
end

avgAllISIOpto = mean(LicksISIintAvg_Opto(:, 2));

% Save the results for First_Opto to a CSV
filename_Opto = fullfile(directory, 'LicksISIintAvg_Opto.csv');
writematrix(LicksISIintAvg_Opto, filename_Opto);
disp(['Data for First_Opto saved to: ', filename_Opto]);

% Process First_NoOpto
numIntervals = length(First_RewardNotOpto);

% Initialize the matrix to store the SBurst timestamps and average ISIs for First_NoOpto
LicksISIintAvg_NotOpto = [];

for i = 1:numIntervals-1
    start_time = First_RewardNotOpto(i);
    end_time = Last_RewardNotOpto(i);

    rewards_in_interval = Reward(Reward >= start_time & Reward <= end_time);

    if length(rewards_in_interval) > 1
        time_differences = diff(rewards_in_interval);
        avg_LicksISI = mean(time_differences);
        LicksISIintAvg_NotOpto = [LicksISIintAvg_NotOpto; First_RewardNotOpto(i), avg_LicksISI];
    else
        LicksISIintAvg_NotOpto = [LicksISIintAvg_NotOpto; First_RewardNotOpto(i), NaN];
    end
end

avgAllISINotOpto = mean(LicksISIintAvg_NotOpto(:, 2));

% Save the results for First_NoOpto to a CSV
filename_NotOpto = fullfile(directory, 'LicksISIintAvg_NotOpto.csv');
writematrix(LicksISIintAvg_NotOpto, filename_NotOpto);
disp(['Data for First_NotOpto saved to: ', filename_NotOpto]);

%% Random Retract
% Your main script (lickHzandgetanalogtimestampslick.m)
% Some preprocessing or loading code here

% Call the function
[First20, First40, First100, FirstE] = classify_reward_intervals(Last_Invol, Reward);

% Your function must be at the bottom of the script
function [First20, First40, First100, FirstE] = classify_reward_intervals(Last_Invol, Reward)
    % Initialize outputs as empty arrays
    First20 = [];
    First40 = [];
    First100 = [];
    FirstE = [];
    
    % Include 0 as the first interval start
    interval_starts = [0; Last_Invol(:)];
    
    % Iterate through intervals
    for i = 1:length(interval_starts)-1
        start_time = interval_starts(i);
        end_time = interval_starts(i+1);
        
        % Find rewards within the interval
        rewards_in_interval = Reward(Reward > start_time & Reward <= end_time);
        num_rewards = length(rewards_in_interval);
        
        % Check if rewards count fits any category
        if abs(num_rewards - 20) <= 3
            First20 = [First20; rewards_in_interval(1)];
        elseif abs(num_rewards - 40) <= 3
            First40 = [First40; rewards_in_interval(1)];
        elseif abs(num_rewards - 100) <= 3
            First100 = [First100; rewards_in_interval(1)];
        else
            FirstE = [FirstE; rewards_in_interval(1)];
        end
    end
end

