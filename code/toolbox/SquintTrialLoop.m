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

%% Set some local variables with values from the protocolParams
speakRateDefault = getpref(protocolParams.approach, 'SpeakRateDefault');


%% Initialize events variable
events = struct;


%% Establish myRole
% Get local computer name
localHostName = UDPcommunicator2.getLocalHostName();
% Find which hostName is contained within my computer name
idxWhichHostAmI = find(cellfun(@(x) contains(localHostName, x), protocolParams.hostNames));
if isempty(idxWhichHostAmI)
    error(['My local host name (' localHostName ') does not match an available host name']);
end
% Assign me the role corresponding to my host name
myRole = protocolParams.hostRoles{idxWhichHostAmI};


%% Pre trial loop actions

% Instantiate our UDPcommunicator object
UDPobj = UDPcommunicator2.instantiateObject(localHostName, protocolParams.hostNames, protocolParams.hostIPs, 'beVerbose', protocolParams.verbose);
% Establish the communication
triggerMessage = 'Go!';
UDPobj.initiateCommunication(localHostName, protocolParams.hostRoles,  protocolParams.hostNames, triggerMessage, 'beVerbose', protocolParams.verbose);
% Report success
if protocolParams.verbose
    fprintf('UDP communication established\n');
end
% Construct the basic communication packet for the base and peripheral
baseHostName = protocolParams.hostNames{cellfun(@(x) strcmp(x,'base'), protocolParams.hostRoles)};
emgPeripheralHostName = protocolParams.hostNames{cellfun(@(x) strcmp(x,'satellite'), protocolParams.hostRoles)};
trialPacketRootFromBase = UDPcommunicator2.makePacket(protocolParams.hostNames,...
        [baseHostName ' -> ' emgPeripheralHostName], 'Trial start and duration from base', ...
        'timeOutSecs', 1.0, ...                                         % Wait for 1 secs to receive this message. I'm the base so I'm impatient
        'timeOutAction', UDPcommunicator2.NOTIFY_CALLER, ...            % Do not throw an error, notify caller function instead (choose from UDPcommunicator2.{NOTIFY_CALLER, THROW_ERROR})
        'withData', struct('action','trial','duration',0) ...
        );
trialPacketForSatellite = UDPcommunicator2.makePacket(protocolParams.hostNames,...
        [baseHostName ' -> ' emgPeripheralHostName], 'Trial start and duration from base', ...
        'timeOutSecs', 3600, ...                                        % Sit and wait up to an hour for my instruction 
        'timeOutAction', UDPcommunicator2.NOTIFY_CALLER, ...            % Do not throw an error, notify caller function instead (choose from UDPcommunicator2.{NOTIFY_CALLER, THROW_ERROR})
         'badTransmissionAction', UDPcommunicator2.NOTIFY_CALLER ...    % Do not throw an error, notify caller function instead (choose from UDPcommunicator2.{NOTIFY_CALLER, THROW_ERROR})
        );

% Role dependent actions
switch myRole    
    case 'satellite'
        if protocolParams.verbose
            fprintf('EMG computer ready to start trials\n');
        end
        % If simulating, make a window to show the simulated EMG signal if I am the
        % EMG_peripheral
        if protocolParams.simulate && strcmp(myRole,'EMG_peripheral')
            responseStructFigHandle = figure();
            responseStructPlotHandle=gca(responseStructFigHandle);
        end
    case 'base'
        % Suppress keypresses going to the Matlab window and flush keyboard queue.
        %
        % This code is a curious mixture of PTB and mgl calls.  Not sure we need to
        % ListenChar(2), but not sure we don't.
        ListenChar(2);
        while (~isempty(mglGetKeyEvent)), end
        
        Speak('Press key to start experiment', [], speakRateDefault);
        if (~protocolParams.simulate), WaitForKeyPress; end
        fprintf('* <strong>Experiment started</strong>\n');
        if (protocolParams.verbose), fprintf('- Starting trials.\n'); end
    otherwise
        error('This is not a known identity role for the experiment');
end


%% Trial loop actions
for trial = 1:protocolParams.nTrials
    
    % Take the appropriate action
    switch myRole
        case 'satellite'
            % Wait for the trial packet from the base
            [theMessageReceived, theCommunicationStatus, roundTipDelayMilliSecs] = ...
                UDPobj.communicate(...
                localHostName, trial, trialPacketForSatellite, ...
                'beVerbose', protocolParams.verbose, ...
                'displayPackets', protocolParams.verbose...
                );

            durationForThisTrial = theMessageReceived.withData.duration;
            
            % Announce that we are proceeding with the trial
            if (protocolParams.verbose)
                fprintf('* Recording for trial %i/%i - %s,\n', trial, protocolParams.nTrials, block(trial).modulationData.modulationParams.direction);
            end

            [emgDataStruct] = SquintRecordEMG(...
                'recordingDurationSecs', durationForThisTrial, ...
                'simulate', protocolParams.simulate,...
                'verbose', protocolParams.verbose);
            if protocolParams.simulate
                plot(responseStructPlotHandle,emgDataStruct.timebase,emgDataStruct.response);
                drawnow
            end
            
            % REPORT SUCCESS BACK TO THE base
            
            % Add a pause here for debugging purposes
            mglWaitSecs(1);
            
        case 'base'
            
            % Build the UDP communication packet for this trial
            trialPacketFromBase = trialPacketRootFromBase;
            trialPacketFromBase.messageData.duration = ...
                block(trial).modulationData.modulationParams.stimulusDuration;
            
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
            
            % Start trial.  Present the background spectrum
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
            
            % Inform the peripheral that it is time to record
            [theMessageReceived, theCommunicationStatus, roundTipDelayMilliSecs] = ...
                UDPobj.communicate(...
                localHostName, trial, trialPacketFromBase, ...
                'beVerbose', protocolParams.verbose, ...
                'displayPackets', protocolParams.verbose...
                );
         
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


%% Post trial loop actions

% Record when the block ended
tBlockEnd = mglGetSecs;
if (protocolParams.verbose), fprintf('- Done with block.\n'); end

switch myRole
    case 'satellite'
        responseStruct = [];
    case 'base'
        %  undo key listening
        ListenChar(0);
        % Put the trial information into the response struct
        responseStruct.events = events;
end




end % SquintTrialLoop function
