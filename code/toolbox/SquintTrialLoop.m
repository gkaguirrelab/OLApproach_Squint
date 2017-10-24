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
if protocolParams.simulate.udp
    % If we are simulating the UDP connection stream, then we will operate
    % as the base and simulate the satellite component when needed.
    myRole = {'base','satellite'};
else
    % Get local computer name
    localHostName = UDPcommunicator2.getLocalHostName();
    % Find which hostName is contained within my computer name
    idxWhichHostAmI = find(cellfun(@(x) contains(localHostName, x), protocolParams.hostNames));
    if isempty(idxWhichHostAmI)
        error(['My local host name (' localHostName ') does not match an available host name']);
    end
    % Assign me the role corresponding to my host name
    myRole = protocolParams.hostRoles{idxWhichHostAmI};
end

%% Pre trial loop actions

if protocolParams.simulate.udp
    if protocolParams.verbose
        fprintf('[simulate] UDP communication established\n');
    end
else
    % Instantiate our UDPcommunicator object
    UDPobj = UDPcommunicator2.instantiateObject(localHostName, protocolParams.hostNames, protocolParams.hostIPs, 'beVerbose', protocolParams.verbose);
    % Establish the communication
    triggerMessage = 'Go!';
    UDPobj.initiateCommunication(localHostName, protocolParams.hostRoles,  protocolParams.hostNames, triggerMessage, 'beVerbose', protocolParams.verbose);
    % Report success
    if protocolParams.verbose
        fprintf('UDP communication established\n');
    end
end

% Role dependent actions
if any(strcmp('base',myRole))
    
    % Construct initial config communication packet for the base
    baseHostName = protocolParams.hostNames{cellfun(@(x) strcmp(x,'base'), protocolParams.hostRoles)};
    emgPeripheralHostName = protocolParams.hostNames{cellfun(@(x) strcmp(x,'satellite'), protocolParams.hostRoles)};
    configPacketFromBase = UDPcommunicator2.makePacket(protocolParams.hostNames,...
        [baseHostName ' -> ' emgPeripheralHostName], 'Acquisition parameters', ...
        'timeOutSecs', 1.0, ...                                         % Wait for 1 secs to receive this message. I'm the base so I'm impatient
        'timeOutAction', UDPcommunicator2.NOTIFY_CALLER, ...            % Do not throw an error, notify caller function instead (choose from UDPcommunicator2.{NOTIFY_CALLER, THROW_ERROR})
        'withData', struct( ...
        'action','config', ...
        'acquisitionNumber', protocolParams.acquisitionNumber, ...
        'sessionName', protocolParams.sessionName, ...
        'observerID', protocolParams.observerID, ...
        'todayDate', protocolParams.todayDate, ...
        'protocolOutputName', protocolParams.protocolOutputName) ...        
        );
    
    % Pass the config packet
    if protocolParams.simulate.udp
        if protocolParams.verbose
            fprintf('[simulate] base sending config packet via UDP\n');
        end
    else
        [theMessageReceived, theCommunicationStatus, roundTipDelayMilliSecs] = ...
            UDPobj.communicate(...
            localHostName, 0, configPacketFromBase, ...
            'beVerbose', protocolParams.verbose, ...
            'displayPackets', protocolParams.verbose...
            );
    end
    
    % Suppress keypresses going to the Matlab window and flush keyboard queue.
    %
    % This code is a curious mixture of PTB and mgl calls.  Not sure we need to
    % ListenChar(2), but not sure we don't.
    ListenChar(2);
    while (~isempty(mglGetKeyEvent)), end
    
    Speak('Press key to start experiment', [], speakRateDefault);
    if protocolParams.simulate.observer
        if protocolParams.verbose
            fprintf('[simulate] Observer pressed a key\n');
        end
    else
        WaitForKeyPress
    end
    fprintf('* <strong>Experiment started</strong>\n');
    if (protocolParams.verbose), fprintf('- Starting trials.\n'); end
end


if any(strcmp('satellite',myRole))

    % Construct initial config communication packet for the base
    configPacketForSatellite = UDPcommunicator2.makePacket(protocolParams.hostNames,...
        [baseHostName ' -> ' emgPeripheralHostName], 'Acquisition parameters', ...
        'timeOutSecs', 3600, ...                                        % Sit and wait up to an hour for my instruction 
        'timeOutAction', UDPcommunicator2.NOTIFY_CALLER, ...            % Do not throw an error, notify caller function instead (choose from UDPcommunicator2.{NOTIFY_CALLER, THROW_ERROR})
         'badTransmissionAction', UDPcommunicator2.NOTIFY_CALLER ...    % Do not throw an error, notify caller function instead (choose from UDPcommunicator2.{NOTIFY_CALLER, THROW_ERROR})
        );
    
        % Wait for the config packet from the base
        if protocolParams.simulate.udp
            % If we are in udp simulation mode then the protocol params are
            % available as we are acting both as the base  and the
            % satellite
            if protocolParams.verbose
                fprintf('[simulate] satellite receiving config packet via UDP\n');
            end
        else
            [theMessageReceived, theCommunicationStatus, roundTipDelayMilliSecs] = ...
                UDPobj.communicate(...
                localHostName, 0, configPacketForSatellite, ...
                'beVerbose', protocolParams.verbose, ...
                'displayPackets', protocolParams.verbose...
                );
            protocolParams.acquisitionNumber = theMessageReceived.data.acquisitionNumber;
            protocolParams.sessionName = theMessageReceived.data.sessionName;
            protocolParams.protocolOutputName = theMessageReceived.data.protocolOutputName;
            protocolParams.observerID = theMessageReceived.data.observerID;
            protocolParams.todayDate = theMessageReceived.data.todayDate;
        end

    
    if protocolParams.verbose
        fprintf('EMG computer ready to start trials\n');
    end
    % If simulating, make a window to show the simulated EMG signal if I am the
    % satellite
    if protocolParams.simulate.emg && protocolParams.simulate.makePlots && any(strcmp(myRole,'satellite'))
        responseStructFigHandle = figure();
        responseStructPlotHandle=gca(responseStructFigHandle);
    end
end
        
% Construct the basic trial communication packet for the base and peripheral
baseHostName = protocolParams.hostNames{cellfun(@(x) strcmp(x,'base'), protocolParams.hostRoles)};
emgPeripheralHostName = protocolParams.hostNames{cellfun(@(x) strcmp(x,'satellite'), protocolParams.hostRoles)};
trialPacketRootFromBase = UDPcommunicator2.makePacket(protocolParams.hostNames,...
        [baseHostName ' -> ' emgPeripheralHostName], 'Parameters for this trial from base', ...
        'timeOutSecs', 1.0, ...                                         % Wait for 1 secs to receive this message. I'm the base so I'm impatient
        'timeOutAction', UDPcommunicator2.NOTIFY_CALLER, ...            % Do not throw an error, notify caller function instead (choose from UDPcommunicator2.{NOTIFY_CALLER, THROW_ERROR})
        'withData', struct('action','trial','duration',0,'direction','') ...
        );
trialPacketForSatellite = UDPcommunicator2.makePacket(protocolParams.hostNames,...
        [baseHostName ' -> ' emgPeripheralHostName], 'Parameters for this trial from base', ...
        'timeOutSecs', 3600, ...                                        % Sit and wait up to an hour for my instruction 
        'timeOutAction', UDPcommunicator2.NOTIFY_CALLER, ...            % Do not throw an error, notify caller function instead (choose from UDPcommunicator2.{NOTIFY_CALLER, THROW_ERROR})
         'badTransmissionAction', UDPcommunicator2.NOTIFY_CALLER ...    % Do not throw an error, notify caller function instead (choose from UDPcommunicator2.{NOTIFY_CALLER, THROW_ERROR})
        );

    
%% Trial loop actions
for trial = 1:protocolParams.nTrials
    
    % Role dependent actions - BASE
    if any(strcmp('base',myRole))
        
        % Build the UDP communication packet for this trial
        trialPacketFromBase = trialPacketRootFromBase;
        trialPacketFromBase.messageData.duration = ...
            block(trial).modulationData.modulationParams.stimulusDuration;
        trialPacketFromBase.messageData.direction = ...
            block(trial).modulationData.modulationParams.direction;
        
        % Announce trial
        if (protocolParams.verbose)
            fprintf('* Start trial %i/%i - %s,\n', trial, protocolParams.nTrials, block(trial).modulationData.modulationParams.direction);
        end
        
        % MAKE NOISE TO ALERT SUBJECT THAT WE NEED THEM TO PRESS A BUTTON
        
        % Wait for button press from subject
        if protocolParams.simulate.observer
            if protocolParams.verbose
                fprintf('[simulate] Observer pressed a key\n');
            end
        else
            WaitForKeyPress
        end
        
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
        if protocolParams.simulate.udp
            if protocolParams.verbose
                fprintf('[simulate] base sending packet via UDP\n');
            end
        else
            [theMessageReceived, theCommunicationStatus, roundTipDelayMilliSecs] = ...
                UDPobj.communicate(...
                localHostName, trial, trialPacketFromBase, ...
                'beVerbose', protocolParams.verbose, ...
                'displayPackets', protocolParams.verbose...
                );
        end
        
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
    end % base actions
    
    
    % Role dependent actions - SATELLITE
    if any(strcmp('satellite',myRole))

        % Wait for the trial packet from the base
        if protocolParams.simulate.udp
            theMessageReceived.data.duration = block(trial).modulationData.modulationParams.stimulusDuration;
            theMessageReceived.data.direction = block(trial).modulationData.modulationParams.direction;
            if protocolParams.verbose
                fprintf('[simulate] satellite receiving packet via UDP\n');
            end
        else
            [theMessageReceived, theCommunicationStatus, roundTipDelayMilliSecs] = ...
                UDPobj.communicate(...
                localHostName, trial, trialPacketForSatellite, ...
                'beVerbose', protocolParams.verbose, ...
                'displayPackets', protocolParams.verbose...
                );
        end
        
        durationForThisTrial = theMessageReceived.data.duration;
        directionForThisTrial = theMessageReceived.data.direction;
        
        % Announce that we are proceeding with the trial
        if (protocolParams.verbose)
            fprintf('* Recording for trial %i/%i - %s,\n', trial, protocolParams.nTrials, directionForThisTrial);
        end
        
        emgDataStruct(trial) = SquintRecordEMG(...
            'recordingDurationSecs', durationForThisTrial, ...
            'simulate', protocolParams.simulate.emg, ...
            'verbose', protocolParams.verbose);
        
        if protocolParams.simulate.emg && protocolParams.simulate.makePlots
                plot(responseStructPlotHandle,emgDataStruct(trial).timebase,emgDataStruct(trial).response);
                drawnow
        end
        
        % REPORT SUCCESS BACK TO THE base
        
        % Add a pause here for debugging purposes
        mglWaitSecs(1);
        
    end
    
end % Loop over trials


%% Post trial loop actions

% Record when the block ended
tBlockEnd = mglGetSecs;
if (protocolParams.verbose), fprintf('- Done with block.\n'); end

% Role dependent actions - BASE
if any(strcmp('base',myRole))
    %  undo key listening
    ListenChar(0);
    % Put the trial information into the response struct
    responseStruct.events = events;
end

% Role dependent actions - SATELLITE
if any(strcmp('satellite',myRole))
    responseStruct.emgData = emgDataStruct;
end


end % SquintTrialLoop function
