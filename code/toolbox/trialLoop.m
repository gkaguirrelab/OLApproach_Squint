function protocolParams = trialLoop(protocolParams,block,ol)
% [params, responseStruct] = trialLoop(params, cacheData)
%
% THE IS THE EXPERIMENT
% This function runs the experiment loop

%% Store out the primaries from the cacheData into a cell.  The length of
% cacheData corresponds to the number of different stimuli that are being
% shown

% Set the background to the 'idle' background appropriate for this
% trial.
fprintf('- Setting mirrors to background, waiting for t.\n');

% Initialize events variable
events = struct();
%events(protocolParams.nTrials).buffer = '';

% Suppress keypresses going to the Matlab window.
ListenChar(2);

% Flush our keyboard queue.
mglGetKeyEvent;

%% Code to wait for 't' -- the go-signal from the scanner
triggerReceived = false;
while ~triggerReceived
    key = mglGetKeyEvent;
    % If a key was pressed, get the key and exit.
    if ~isempty(key)
        keyPress = key.charCode;
        if (strcmp(keyPress,'t'))
            tBlockStart = key.when;
            triggerReceived = true;
            %fprintf('  * t received.\n');
        end
    end
end

% Stop receiving t
fprintf('- Starting trials.\n');

% Iterate over trials
for trial = 1:protocolParams.nTrials
    %if params.waitForKeyPress
    %    ListenChar(0);
    %    pause;
    %end
    fprintf('* Start trial %i/%i - %s,\n', trial, protocolParams.nTrials, block(trial).modulationData.params.direction);
    % Launch into OLPDFlickerSettings.
    events(trial).tTrialStart = mglGetSecs;
    % this send the flicker starts stops to the OL
    [events(trial).buffer, events(trial).t,  events(trial).counter] = ModulationTrialSequenceFlickerStartsStops(ol, block, trial, block(trial).modulationData.params.timeStep, 1);
    events(trial).tTrialEnd = mglGetSecs;
    events(trial).attentionTask = block(trial).attentionTask;
    events(trial).powerLevels = block(trial).modulationData.modulation.powerLevels;
end
tBlockEnd = mglGetSecs;

fprintf('- Done with block.\n');
ListenChar(0);

% Turn all mirrors off
%ol.setAll(false);

% Put the event information in the struct
responseStruct.events = events;
responseStruct.tBlockStart = tBlockStart;
responseStruct.tBlockEnd = tBlockEnd;

fprintf('Total duration: %f s\n', responseStruct.tBlockEnd-responseStruct.tBlockStart);

% Tack data that we want for later analysis onto params structure.  It then
% gets passed back to the calling routine and saved in our standard place.
protocolParams.responseStruct = responseStruct;

end
