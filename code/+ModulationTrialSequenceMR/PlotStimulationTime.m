function PlotStimulationTime(responseStruct,varargin)
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


for i = 1:length(responseStruct.events)
    trialStartTime(i) = responseStruct.events(i).tTrialStart - responseStruct.tBlockStart;
    trialEndTime(i) = responseStruct.events(i).tTrialEnd - responseStruct.tBlockStart;
    trialWaitTime(i) = trialStartTime(i) + responseStruct.events(i).trialWaitTime;
end


figure; hold on;
for ii = 1:length(responseStruct.events)
    plot([trialStartTime(ii) trialStartTime(ii)], [-1 1],'r');
    plot([trialEndTime(ii) trialEndTime(ii)], [-1 1],'b');
    plot([trialWaitTime(ii) trialWaitTime(ii) ], [-1 1],'g--');
end