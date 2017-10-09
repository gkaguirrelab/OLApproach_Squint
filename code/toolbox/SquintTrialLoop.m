function responseStruct = SquintTrialLoop(protocolParams,block,ol,varargin)
%%SquintTrialLoop  Loop over trials, show stimuli and get responses.
%
% Usage:
%    responseStruct = trialLoop(protocolParams,block,ol)
%
% Description:
%    The routine runs the trials for a squint expriment.
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

%% Speaking rate
speakRateDefault = getpref(protocolParams.approach, 'SpeakRateDefault');

%% Initialize events variable
events = struct;

%% Suppress keypresses going to the Matlab window and flush keyboard queue.
%
% This code is a curious mixture of PTB and mgl calls.  Not sure we need to
% ListenChar(2), but not sure we don't.
%ListenChar(2);
%while (~isempty(mglGetKeyEvent)), end

%% If simulating, make a window to show the simulated EMG signal
if protocolParams.simulate
    responseStructFigHandle = figure();
    responseStructPlotHandle=gca(responseStructFigHandle);
end

%% Wait for key press
Speak('Press key to start experiment', [], speakRateDefault);
if (~protocolParams.simulate), WaitForKeyPress; end
fprintf('* <strong>Experiment started</strong>\n');

%% Do trials
if (protocolParams.verbose), fprintf('- Starting trials.\n'); end
for trial = 1:protocolParams.nTrials
    
    myIdentity = 'EMG_peripheral';
    %% AT THIS STAGE THE MASTER AND PERIPHERAL TAKE DIFFERENT ACTIONS
    switch myIdentity
        case 'EMG_peripheral'
            % LISTEN FOR SIGNAL FROM MASTER THAT IT IS TIME TO RECORD
            [emgDataStruct] = SquintRecordEMG(...
                'recordingDurationSecs', block(trial).modulationData.protocolParams.trialDuration, ...
                'simulate', protocolParams.simulate,...
                'verbose', protocolParams.verbose);
            if protocolParams.simulate
                plot(responseStructPlotHandle,emgDataStruct.timebase,emgDataStruct.response);
            end
            % REPORT SUCCESS BACK TO THE MASTER
            
        case 'master'
            
            % Announce trial
            if (protocolParams.verbose)
                fprintf('* Start trial %i/%i - %s,\n', trial, protocolParams.nTrials, block(trial).modulationData.modulationParams.direction);
            end
            
            % MAKE NOISE TO ALERT SUBJECT THAT WE NEED THEM TO PRESS A BUTTON
            
            % ADD STEP HERE TO WAIT FOR BUTTON PRESS FROM THE SUBJECT
            if (~protocolParams.simulate), WaitForKeyPress; end
            
            % MAKE NOISE TO ALERT SUBJECT TRIAL IS ABOUT TO START
            
            % Check that the timing checks out
            assert(block(trial).modulationData.modulationParams.stimulusDuration + protocolParams.isiTime + protocolParams.trialMaxJitterTimeSec ...
                <= protocolParams.trialDuration, 'Stimulus time + max jitter + ISI time is greater than trial durration');
            
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
            % Record start/finish time as well as other information as we go.
            events(trial).tStimulusStart = mglGetSecs;
            
            % ALERT THE PERIPHERAL THAT IT IS TIME TO RECORD
            
            % Present the modulation
            [events(trial).buffer, events(trial).t,  events(trial).counter] = SquintOLFlicker(ol, block, trial, block(trial).modulationData.modulationParams.timeStep, 1);


            % Put background back up and record times and keypresses.
            ol.setMirrors(block(trial).modulationData.modulation.background.starts, block(trial).modulationData.modulation.background.stops);
            events(trial).tStimulusEnd = mglGetSecs;

            % CHECK IF THE PERIPHERAL REPORTS EVERYTHING WENT OK

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
            
    end % switch identity
end

%% Record when the block ended and undo key listening
tBlockEnd = mglGetSecs;
if (protocolParams.verbose), fprintf('- Done with block.\n'); end
ListenChar(0);

%% Put the trial information into the response struct
responseStruct.events = events;


end
