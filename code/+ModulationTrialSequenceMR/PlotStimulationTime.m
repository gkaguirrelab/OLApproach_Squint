function [] = PlotStimulationTime(responseStruct,block,varargin)
%%PlotStimulationTime - plot the trial timing within an experiment run
%
% Usage:
%    PlotStimulationTime(responseStruct,block,varargin)
%
% Description:
%    This function will take in a responseStruct output from
%    TrialSequenceMRTrialLoop.m and plot the timeing information and pulses
%
% Input:
%    responseStruct (struct)  Structure containing information about what happened on each trial
%
% Output:
%    none as of now
%
% Optional key/value pairs:
%    verbose (logical)         true       Be chatty?

%% Parse input
p = inputParser;
p.addParameter('verbose',true,@islogical);
p.parse(varargin{:});

%% Print out general information about the scan.
if p.Results.verbose == true
    display(sprintf('Scan Number: %s',num2str(responseStruct.scanNumber)))
    display(sprintf('Number of events found: %s', num2str(length(responseStruct.events))))
    display(sprintf('Total scan time length: %s (sec)',num2str(responseStruct.tBlockEnd-responseStruct.tBlockStart)))
end


%% Plotting the power levels and trial starts, trial stops, and trial wait times.
for i = 1:length(responseStruct.events)
    % set up trial start and stop time markers
    trialStartTime(i) = responseStruct.events(i).tTrialStart - responseStruct.tBlockStart;
    trialEndTime(i) = responseStruct.events(i).tTrialEnd - responseStruct.tBlockStart;
    trialWaitTime(i) = trialStartTime(i) + responseStruct.events(i).trialWaitTime;
    
    % set up power level plot relevent vars.
    timeStep = block(i).modulationData.params.timeStep;
    stimulusDuration = block(i).modulationData.params.stimulusDuration;
    sampleBasePowerLevel{i} =  (trialStartTime(i) + responseStruct.events(i).trialWaitTime):timeStep:(trialStartTime(i) + responseStruct.events(i).trialWaitTime+ stimulusDuration -timeStep);
end

% Set up background power level lines
for j = 1:length(responseStruct.events)
    bgTimes{1} = 0:timeStep:trialWaitTime(1)-timeStep;
    if j+1 < length(responseStruct.events)
        bgTimes{j+1} = sampleBasePowerLevel{j}(end):timeStep:trialWaitTime(j+1)-timeStep;
    else
        bgTimes{j+1} = sampleBasePowerLevel{j}(end):timeStep:responseStruct.tBlockEnd-responseStruct.tBlockStart;
    end
end

% plot the trial timing and
figure;subplot(3,1,1); hold on;
for ii = 1:length(responseStruct.events)
    plot([trialStartTime(ii) trialStartTime(ii)]-0.1, [-1 1],'r','LineWidth',2);
    plot([trialEndTime(ii) trialEndTime(ii)], [-1 1],'b','LineWidth',2);
    plot([trialWaitTime(ii) trialWaitTime(ii) ], [-1 1],'g--');
    plot(sampleBasePowerLevel{ii},block(ii).modulationData.modulation.powerLevels,'k');
end

for jj = 1:length(bgTimes)
    plot(bgTimes{jj},zeros(size(bgTimes{jj})),'k')
end
xlabel('Time (seconds)')
ylabel('Contrast Level')
legend('Trial Start Time','Trial End Time', 'Trial Wait Time', 'Power Level')

%% Plotting the attention events
subplot(3,1,2); hold on
clear ii i j jj
for i = 1:length(block)
    if block(i).attentionTask.segmentFlag == 1
        attentionTaskStart{i} = block(i).attentionTask.theStartBlankIndex.*timeStep + trialWaitTime(i);
        attentionTaskStop{i} = block(i).attentionTask.theStartBlankIndex.*timeStep + trialWaitTime(i);
    else
        attentionTaskStart{i} = [];
        attentionTaskStop{i}  = [];
    end
end

for ii = 1:length(block)
    p1 = plot([trialStartTime(ii) trialStartTime(ii)]-0.1, [-1 1],'r','LineWidth',2);
    p2 = plot([trialEndTime(ii) trialEndTime(ii)], [-1 1],'b','LineWidth',2);
    if ~isempty(attentionTaskStart{ii})
        p3 =  plot([attentionTaskStart{ii} attentionTaskStart{ii}], [-1 1],'g--','LineWidth',1);
    end
end

xlabel('Time (seconds)')
legend([p1 p2 p3],'Trial Start Time','Trial End Time','Attention Event')

