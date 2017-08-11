function [] = PlotStimulationTime(responseStruct,block,varargin)
%%SimulationTimeAnalysis - plot the trial timing within an experiment run 
%
% Usage:
%    StimulationTimeAnalysis(responseStruct,varargin)
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

% This is temporary to remind myself of the variables 
%responseStruct.events.tTrialStart
%responseStruct.events.tTrialEnd
%responseStruct.events.trialWaitTime
%responseStruct.tBlockEnd
%responseStruct.tBlockStart

% Print out general information.
if p.Results.verbose == true
    display(sprintf('Scan Number: %s',num2str(responseStruct.scanNumber)))
    display(sprintf('Number of events found: %s', num2str(length(responseStruct.events))))
    display(sprintf('Total scan time length: %s (sec)',num2str(responseStruct.tBlockEnd-responseStruct.tBlockStart)))   
end

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

for j = 1:length(responseStruct.events)
    % set up backround lines
    bgTimes{1} = 0:timeStep:trialStartTime(1)-timeStep;
    if j < length(responseStruct.events)
        bgTimes{1+j} = trialEndTime(j):timeStep:trialStartTime(j+1)-timeStep;
    else
        bgTimes{1+j} = trialEndTime(j):timeStep:responseStruct.tBlockEnd-responseStruct.tBlockStart;
    end
end


figure; hold on;
for ii = 1:length(responseStruct.events)
    plot([trialStartTime(ii) trialStartTime(ii)], [-1 1],'r');
    plot([trialEndTime(ii) trialEndTime(ii)], [-1 1],'b');
    plot([trialWaitTime(ii) trialWaitTime(ii) ], [-1 1],'g--');
    plot(sampleBasePowerLevel{ii},block(ii).modulationData.modulation.powerLevels,'k');
end

for jj = 1:length(bgTimes)
    plot(bgTimes{jj},zeros(size(bgTimes{jj})),'k')
end