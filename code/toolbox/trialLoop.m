function responseStruct = trialLoop(protocolParams,block,ol)
%trialLoop - Set mirrors for each trial with optional timing parameters.
%
% Usage:
%    responseStruct = trialLoop(protocolParams,block,ol)
%
% Description:
%    Master program for running sequences of OneLight pulses/modulations in the scanner.
%
% Input:
%    ol (object)              An open OneLight object.
%    protocolParams (struct)  The protocol parameters structure.
%    block (struct)           Contains trial-by-trial starts/stops and other info.
%
% Output:
%    responseStruct (struct)   
%
% Optional key/value pairs:   Contains trial key responses and timing info.
%    none.

%% Initialize events variable
events = struct;

%% Suppress keypresses going to the Matlab window and flush keyboard queue.
%
% This code is a curious mixture of PTB and mgl calls.  Not sure we need to
% ListenChar(2), but not sure we don't
ListenChar(2);
while (~mglGetKeyEvent), end

%% Wait for 't' -- the go-signal from the scanner
%
% This waits for a key, checks if it is a 't' and just
% keeps waiting until it gets one.
if (protocolParams.verbose), fprintf('- Waiting for t.\n'); end
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
    
    % Stick in background for this trial
    ol.setMirrors(block(1).modulationData.modulation.background.starts, block(1).modulationData.modulation.background.stops); 

    % Trial jitter and ISI is invoked here
    
    % Randomly assign a jitter time between protocolParams.trialMinJitterTimeSec and protocolParams.trialMaxJitterTimeSec
    jitterTime  = protocolParams.trialMinJitterTimeSec + (protocolParams.trialMaxJitterTimeSec-protocolParams.trialMinJitterTimeSec).*rand(1);
    
    % Set the total time to wait equal to the ISI time plus the jitter time
    totalWaitTime =  protocolParams.isiTime + jitterTime; 
    
    % Save out the totalWaitTime for each trial
    events(trial).trialWaitTime = totalWaitTime;
    
    % Reference start time
    startTime = mglGetSecs;
    
    % Initalize currentTime to zero
    currentTime = 0;
    
    % Wait untill totalWaitTime has elaplsed.
    while currentTime < totalWaitTime
        currentTime = mglGetSecs - startTime;
    end
    
    % Record trial start time
    events(trial).tTrialStart = mglGetSecs;
    
    % Show the trial and get any returned keys corresponding to the trial
    [events(trial).buffer, events(trial).t,  events(trial).counter] = TrialSequenceMROLFlicker(ol, block, trial, block(trial).modulationData.params.timeStep, 1);
    
    % Record trial finish time
    events(trial).tTrialEnd = mglGetSecs;
    events(trial).attentionTask = block(trial).attentionTask;
    events(trial).powerLevels = block(trial).modulationData.modulation.powerLevels;
end

%% Wait for any last key presses and grab them
%
% Need to define a protocol param for how long to wait here.
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
