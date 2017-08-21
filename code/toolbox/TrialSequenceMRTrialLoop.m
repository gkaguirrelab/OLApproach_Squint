function responseStruct = TrialSequenceMRTrialLoop(protocolParams,block,ol,varargin)
%%TrialSequenceMRTrialLoop  Loop over trials, show stimuli and get responses.
%
% Usage:
%    responseStruct = trialLoop(protocolParams,block,ol)
%
% Description:
%    The routine runs the trials for an MR expriment.  It waits for the intial 't'
%    and then sets background, shows trial, and collects up key presses.
%
%    The returned responseStruct says what happened on each trial.
%
% Input:
%    protocolParams (struct)  The protocol parameters structure.
%    block (struct)           Contains trial-by-trial starts/stops and other info.
%    ol (object)              An open OneLight object.
%
% Output:
%    responseStruct (struct)  Structure containing information about what happened on each trial 
%
% Optional key/value pairs:
%    verbose (logical)         true       Be chatty?

%% Parse input
p = inputParser;
p.addParameter('verbose',true,@islogical);
p.parse(varargin{:});

%% Initialize events variable
events = struct;

%% Suppress keypresses going to the Matlab window and flush keyboard queue.
%
% This code is a curious mixture of PTB and mgl calls.  Not sure we need to
% ListenChar(2), but not sure we don't.
ListenChar(2);
while (~isempty(mglGetKeyEvent)), end

%% Wait for 't' -- the go-signal from the scanner
%
% This waits for a key, checks if it is a 't' and just
% keeps waiting until it gets one.
if (p.Results.verbose), fprintf('- Waiting for t.\n'); end
triggerReceived = false;
while ~triggerReceived
    key = mglGetKeyEvent;
    % If a key was pressed, get the key and exit.
    if ~isempty(key)
        keyPress = key.charCode;
        if (strcmp(keyPress,'t'))
            tBlockStart = key.when;
            triggerReceived = true;
            if (protocolParams.verbose), fprintf('  * t received.\n'); end
        end
    end
end

%% Do trials
if (protocolParams.verbose), fprintf('- Starting trials.\n'); end
for trial = 1:protocolParams.nTrials
    % Announce trial
    if (protocolParams.verbose)
        fprintf('* Start trial %i/%i - %s,\n', trial, protocolParams.nTrials, block(trial).modulationData.params.direction);
    end
    
    % Check that the timing checks out
    assert(block(trial).modulationData.params.stimulusDuration + protocolParams.isiTime + protocolParams.trialMaxJitterTimeSec ...
       < protocolParams.trialDuration, 'Stimulus time + max jitter + ISI time is greater than trial durration');
    
    % Start trial.  Stick in background
    events(trial).tTrialStart = mglGetSecs;
    ol.setMirrors(block(trial).modulationData.modulation.background.starts, block(trial).modulationData.modulation.background.stops); 

    % Wait for ISI, including random jitter.
    %
    % First, randomly assign a jitter time between
    % protocolParams.trialMinJitterTimeSec and
    % protocolParams.trialMaxJitterTimeSec. Then, add the jitter time to
    % get the total wait time and record it for this trial Then wait.
    jitterTime  = protocolParams.trialMinJitterTimeSec + (protocolParams.trialMaxJitterTimeSec-protocolParams.trialMinJitterTimeSec).*rand(1);
    totalWaitTime =  protocolParams.isiTime + jitterTime;
    events(trial).trialWaitTime = totalWaitTime;
    mglWaitSecs(totalWaitTime);
    
    % Show the trial and get any returned keys corresponding to the trial.
    %
    % Record start/finish time as well as other informatoin as we go.
    events(trial).tStimulusStart = mglGetSecs;
    [events(trial).buffer, events(trial).t,  events(trial).counter] = TrialSequenceMROLFlicker(ol, block, trial, block(trial).modulationData.params.timeStep, 1);
    
    % Put background back up and record times and keypresses.
    ol.setMirrors(block(trial).modulationData.modulation.background.starts, block(trial).modulationData.modulation.background.stops);
    events(trial).tStimulusEnd = mglGetSecs;
    
    % This just makes it easier for us to plot the waveform we think showed on this trial later on.
    events(trial).powerLevels = block(trial).modulationData.modulation.powerLevels;
    
    % At end of trial, put background to be that trial's background.
    %
    % Most modulations will end at their background, so this probably won't have
    % any visible effect.
    
    % Wait for the remaining time for protocolParams.trialDuration to have
    % passed since the start time. 
    trialTimeRemaining =  protocolParams.trialDuration - (mglGetSecs - events(trial).tTrialStart);
    mglWaitSecs(trialTimeRemaining);
    events(trial).tTrialEnd = mglGetSecs;
end

%% Wait for any last key presses and grab them
mglWaitSecs(protocolParams.postAllTrialsWaitForKeysTime)
postTrialLoopKeyPresses = mglListener('getAllKeyEvents');

%% Record when the block ended and undo key listening
tBlockEnd = mglGetSecs;
if (protocolParams.verbose), fprintf('- Done with block.\n'); end
ListenChar(0);

%% Put the trial information into the response struct
responseStruct.events = events;
responseStruct.tBlockStart = tBlockStart;
responseStruct.tBlockEnd = tBlockEnd;
responseStruct.postTrialLoopKeyPresses = postTrialLoopKeyPresses;
if (protocolParams.verbose), fprintf('Total duration: %f s\n', responseStruct.tBlockEnd-responseStruct.tBlockStart); end

end
