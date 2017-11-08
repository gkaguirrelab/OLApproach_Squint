function responseStruct = SquintTrialLoop(protocolParams,block,ol,varargin)
%% SquintTrialLoop  Loop over trials, show stimuli and get responses.
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


%% Initialize events variable and establish roles
events = struct;

% Establish myRole and myActions
if protocolParams.simulate.udp
    % If we are simulating the UDP connection stream, then we will operate
    % as the base and simulate the satellite component when needed.
    myRoles = {'base','satellite','satellite'};
else
    % Get local computer name
    localHostName = UDPcommunicator2.getLocalHostName();
    % Find which hostName is contained within my computer name
    idxWhichHostAmI = find(cellfun(@(x) contains(localHostName, x), protocolParams.hostNames));
    if isempty(idxWhichHostAmI)
        error(['My local host name (' localHostName ') does not match an available host name']);
    end
    % Assign me the role corresponding to my host name
    myRoles = protocolParams.hostRoles{idxWhichHostAmI};
    if ~iscell(myRoles)
        myRoles={myRoles};
    end
end

if protocolParams.simulate.udp
    % If we are simulating the UDP connection stream, then we will execute
    % all actions in this routine.
    myActions = {{'operator','observer','oneLight'}, 'pupil', 'emg'};
else
    % Get local computer name
    localHostName = UDPcommunicator2.getLocalHostName();
    % Find which hostName is contained within my computer name
    idxWhichHostAmI = find(cellfun(@(x) contains(localHostName, x), protocolParams.hostNames));
    if isempty(idxWhichHostAmI)
        error(['My local host name (' localHostName ') does not match an available host name']);
    end
    % Assign me the actions corresponding to my host name
    myActions = protocolParams.hostActions{idxWhichHostAmI};
    if ~iscell(myActions)
        myActions={myActions};
    end
end


%% Pre trial loop actions

% Role independent actions

% Establish the name of the base
baseHostName = protocolParams.hostNames{cellfun(@(x) strcmp(x,'base'), protocolParams.hostRoles)};
% Find the number of satellites and their indices
satelliteIdx = find(strcmp(protocolParams.hostRoles,'satellite'));
numSatellites = length(satelliteIdx);
% Instantiate our UDPcommunicator object
if protocolParams.simulate.udp
    if protocolParams.verbose
        fprintf('[simulate] UDP communication established\n');
    end
else
UDPobj = UDPBaseSatelliteCommunicator.instantiateObject(protocolParams.hostNames, protocolParams.hostIPs, protocolParams.hostRoles, protocolParams.verbose);
% Establish the communication
    triggerMessage = 'Go!';
    allSatellitesAreAGOMessage = 'All Satellites Are Go!';
    UDPobj.initiateCommunication(protocolParams.hostRoles,  protocolParams.hostNames, triggerMessage, allSatellitesAreAGOMessage, 'beVerbose', protocolParams.verbose);
    % Report success
    if protocolParams.verbose
        fprintf('UDP communication established\n');
    end
end
    
% Role dependent actions -- BASE
if any(strcmp('base',myRoles))
    
    % Create and send an initial configuration packet between machines
    if protocolParams.simulate.udp
        if protocolParams.verbose
            fprintf('[simulate] base sending config packet via UDP\n');
        end
    else        
        % Construct a send a config packet to each satellite
        for ss = 1:numSatellites
            satelliteHostName = protocolParams.hostNames(satelliteIdx(ss))

            configPacketFromBaseToSatellite = UDPobj.makePacket(...
                satelliteHostName,...                                               % satellite target
                [baseHostName ' -> ' satelliteHostName], ...                        % message direction
                'Acquisition parameters', ...                                       % message label
                'timeOutSecs', 1.0, ...                                             % Wait for 1 secs to receive this message. I'm the base so I'm impatient
                'timeOutAction', UDPBaseSatelliteCommunicator.NOTIFY_CALLER, ...    % Do not throw an error, notify caller function instead (choose from UDPBaseSatelliteCommunicator.{NOTIFY_CALLER, THROW_ERROR})
                'withData', struct( ...                                             % The data
                'action','config', ...
                'acquisitionNumber', protocolParams.acquisitionNumber, ...
                'sessionName', protocolParams.sessionName, ...
                'observerID', protocolParams.observerID, ...
                'todayDate', protocolParams.todayDate, ...
                'protocolOutputName', protocolParams.protocolOutputName) ...
                );
            
            % Send the config packet (which is number zero)
            [theMessageReceived, theCommunicationStatus, roundTripDelayMilliSecs] = ...
                UDPobj.communicate(0, configPacketFromBaseToSatellite, ...
                'beVerbose', protocolParams.verbose, ...
                'displayPackets', protocolParams.verbose...
                );
         
%                 UDPobj.communicate(0, configPacketFromBaseToSatellite, ...
%                 'beVerbose', protocolParams.verbose, ...
%                 'displayPackets', protocolParams.verbose...
%                 );            
        end
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


% Role dependent actions -- SATELLITE
if any(strcmp('satellite',myRoles))
    
    if protocolParams.simulate.udp
        % If we are in UDP simulation mode then the protocol params are
        % available as we are acting both as the base  and the
        % satellite
        if protocolParams.verbose
            fprintf('[simulate] satellite receiving config packet via UDP\n');
        end
        % Make a window to show the simulated signal
        for ss=1:numSatellites
            if protocolParams.simulate.(myActions{satelliteIdx(ss)}) && protocolParams.simulate.makePlots
                responseStructFigHandle.(myActions{satelliteIdx(ss)}) = figure();
                responseStructPlotHandle.(myActions{satelliteIdx(ss)})=gca(responseStructFigHandle.(myActions{satelliteIdx(ss)}));
            end
        end
    else
        satelliteHostName = UDPBaseSatelliteCommunicator.getLocalHostName()
        % Construct initial config communication packet for the satellite
        configPacketForSatelliteFromBase = UDPobj.makePacket(...
            satelliteHostName,...                                                       % satellite target
            [baseHostName ' -> ' satelliteHostName], ...                                % message direction
            'Acquisition parameters', ...                                               % message label
            'timeOutSecs', 3600, ...                                                    % Sit and wait up to an hour for my instruction
            'timeOutAction', UDPBaseSatelliteCommunicator.NOTIFY_CALLER, ...            % Do not throw an error, notify caller function instead (choose from UDPBaseSatelliteCommunicator.{NOTIFY_CALLER, THROW_ERROR})
            'badTransmissionAction', UDPBaseSatelliteCommunicator.NOTIFY_CALLER ...     % Do not throw an error, notify caller function instead (choose from UDPBaseSatelliteCommunicator.{NOTIFY_CALLER, THROW_ERROR})
            );
        
        % Wait for the config packet from the base
        [theMessageReceived, theCommunicationStatus, roundTripDelayMilliSecs] = ...
            UDPobj.communicate(0, configPacketForSatelliteFromBase, ...
                'beVerbose', protocolParams.verbose, ...
                'displayPackets', protocolParams.verbose...
             );
         
%             UDPobj.communicate(...
%             localHostName, 0, configPacketForSatelliteFromBase, ...
%             'beVerbose', protocolParams.verbose, ...
%             'displayPackets', protocolParams.verbose...
%             );

        % Place the information from the message into protocolParams
        protocolParams.acquisitionNumber = theMessageReceived.data.acquisitionNumber;
        protocolParams.sessionName = theMessageReceived.data.sessionName;
        protocolParams.protocolOutputName = theMessageReceived.data.protocolOutputName;
        protocolParams.observerID = theMessageReceived.data.observerID;
        protocolParams.todayDate = theMessageReceived.data.todayDate;
    end
    
    if protocolParams.verbose
        fprintf('Satellite computer ready to start trials\n');
    end
    
end


% Role independent actions
% Construct the basic trial communication packets for the base and the
% satellites

if ~protocolParams.simulate.udp
    for ss = 1:length(satelliteIdx)
        satelliteHostName = protocolParams.hostNames(satelliteIdx(ss));
        satelliteAction = protocolParams.hostActions{satelliteIdx(ss)};
        trialPacketRootFromBase.(satelliteAction) = UDPobj.makePacket(...
            satelliteHostName,...                                               % satellite target
            [baseHostName ' -> ' satelliteHostName], ...                        % message direction
            'Parameters for this trial from base', ...                          % message label
            'timeOutSecs', 1.0, ...                                             % Wait for 1 secs to receive this message. I'm the base so I'm impatient
            'timeOutAction', UDPBaseSatelliteCommunicator.NOTIFY_CALLER, ...    % Do not throw an error, notify caller function instead (choose from UDPBaseSatelliteCommunicator.{NOTIFY_CALLER, THROW_ERROR})
            'withData', struct( ...
            'action','trial', ...
            'duration',0, ...
            'direction','' ...
            ) ...
            );
        
        trialPacketForSatellite.(satelliteAction) = UDPobj.makePacket( ...
            satelliteHostName,...
            [baseHostName ' -> ' satelliteHostName], ...
            'Parameters for this trial from base', ...
            'timeOutSecs', 3600, ...                                        % Sit and wait up to an hour for my instruction
            'timeOutAction', UDPBaseSatelliteCommunicator.NOTIFY_CALLER, ...            % Do not throw an error, notify caller function instead (choose from UDPcommunicator2.{NOTIFY_CALLER, THROW_ERROR})
            'badTransmissionAction', UDPBaseSatelliteCommunicator.NOTIFY_CALLER ...    % Do not throw an error, notify caller function instead (choose from UDPcommunicator2.{NOTIFY_CALLER, THROW_ERROR})
            );
    end
end

%% Trial loop actions
for trial = 1:protocolParams.nTrials
    
    % Role dependent actions - BASE
    if any(strcmp('base',myRoles))
        
        % Build the UDP communication packet for this trial for each
        % satellite
        if ~protocolParams.simulate.udp
            for ss = 1:length(satelliteIdx)
                satelliteAction = protocolParams.hostActions{satelliteIdx(ss)};
                trialPacketFromBase.(satelliteAction) = trialPacketRootFromBase.(satelliteAction);
                trialPacketFromBase.(satelliteAction).messageData.duration = ...
                    block(trial).modulationData.modulationParams.stimulusDuration;
                trialPacketFromBase.(satelliteAction).messageData.direction = ...
                    block(trial).modulationData.modulationParams.direction;
            end
        end
        
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
        
        % Inform the satellites that it is time to record
        if protocolParams.simulate.udp
            if protocolParams.verbose
                fprintf('[simulate] base sending packet via UDP\n');
            end
            events(trial).udpEvents.theMessageReceived = 'simulated';
            events(trial).udpEvents.theCommunicationStatus = 'simulated';
            events(trial).udpEvents.roundTripDelayMilliSecs = 'simulated';
        else
            for ss=1:numSatellites
                satelliteAction = protocolParams.hostActions{satelliteIdx(ss)};
                [theMessageReceived, theCommunicationStatus, roundTripDelayMilliSecs] = ...
                UDPobj.communicate(trial, trialPacketFromBase.(satelliteAction), ...
                    'beVerbose', protocolParams.verbose, ...
                    'displayPackets', protocolParams.verbose...
                );
         
%                     UDPobj.communicate(...
%                     localHostName, trial, trialPacketFromBase.(satelliteAction), ...
%                     'beVerbose', protocolParams.verbose, ...
%                     'displayPackets', protocolParams.verbose...
%                     );
            end
            % Store the message information in the events struct
            events(trial).udpEvents.theMessageReceived = theMessageReceived;
            events(trial).udpEvents.theCommunicationStatus = theCommunicationStatus;
            events(trial).udpEvents.roundTripDelayMilliSecs = roundTripDelayMilliSecs;
        end
        
        % Present the modulation
        [events(trial).buffer, events(trial).t,  events(trial).counter] = ...
            SquintOLFlicker(ol, block, trial, block(trial).modulationData.modulationParams.timeStep, 1);
        
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
        %% THIS COMMENT IS NOT ASSOCIATED WITH THE CODE DOING ANYTHING. REMOVE?
        
        % Wait for the remaining time for protocolParams.trialDuration to have
        % passed since the start time.
        trialTimeRemaining =  protocolParams.trialDuration - (mglGetSecs - events(trial).tTrialStart);
        mglWaitSecs(trialTimeRemaining);
        events(trial).tTrialEnd = mglGetSecs;
        
    end % base actions
    
    
    % Role dependent actions - SATELLITE
    if any(strcmp('satellite',myRoles))
        
        % Wait for the trial packet from the base
        if protocolParams.simulate.udp
            theMessageReceived.data.duration = block(trial).modulationData.modulationParams.stimulusDuration;
            theMessageReceived.data.direction = block(trial).modulationData.modulationParams.direction;
            if protocolParams.verbose
                fprintf('[simulate] satellite received packet via UDP\n');
            end
            % Store the message information in the events struct
            events(trial).udpEvents.theMessageReceived = theMessageReceived;
            events(trial).udpEvents.theCommunicationStatus = 'simulated';
            events(trial).udpEvents.roundTripDelayMilliSecs = 'simulated';
        else
            [theMessageReceived, theCommunicationStatus, roundTripDelayMilliSecs] = ...
                UDPobj.communicate(trial, trialPacketForSatellite.(myActions{1}), ...
                'beVerbose', protocolParams.verbose, ...
                'displayPackets', protocolParams.verbose...
             );
         
%                 UDPobj.communicate(...
%                 trial, trialPacketForSatellite.(myActions{1}), ...
%                 'beVerbose', protocolParams.verbose, ...
%                 'displayPackets', protocolParams.verbose...
%                 );
            % Store the message information in the events struct
            events(trial).udpEvents.theMessageReceived = theMessageReceived;
            events(trial).udpEvents.theCommunicationStatus = theCommunicationStatus;
            events(trial).udpEvents.roundTripDelayMilliSecs = roundTripDelayMilliSecs;
        end
        
        % Announce that we are proceeding with the trial
        if (protocolParams.verbose)
            fprintf('* Recording for trial %i/%i - %s,\n', trial, protocolParams.nTrials, theMessageReceived.data.direction);
        end
        
        % Record start/finish time as well as other information as we go.
        events(trial).tRecordingStart = mglGetSecs;
        
        if any(cellfun(@(x) sum(strcmp(x,'emg')), myActions))
            dataStruct(trial).emg = SquintRecordEMG(...
                'recordingDurationSecs', theMessageReceived.data.duration, ...
                'simulate', protocolParams.simulate.emg, ...
                'verbose', protocolParams.verbose);
            % If we are simulating the emg, show the simulated data
            if protocolParams.simulate.emg && protocolParams.simulate.makePlots
                plot(responseStructPlotHandle.emg,dataStruct(trial).emg.timebase,dataStruct(trial).emg.response);
                drawnow
            end
        end
        
        if any(cellfun(@(x) sum(strcmp(x,'pupil')), myActions))
%             dataStruct(trial).pupil = SquintRecordPupil(...
%                 'recordingDurationSecs', theMessageReceived.data.duration, ...
%                 'simulate', protocolParams.simulate.pupil, ...
%                 'verbose', protocolParams.verbose);
dataStruct(trial).pupil.timebase=0:1:1000;
dataStruct(trial).pupil.response=atan(0:1:1000);
            % If we are simulating the pupil, show the simulated data
            if protocolParams.simulate.pupil && protocolParams.simulate.makePlots
                plot(responseStructPlotHandle.pupil,dataStruct(trial).pupil.timebase,dataStruct(trial).pupil.response);
                drawnow
            end
        end
        
        % Record start/finish time as well as other information as we go.
        events(trial).tRecordingEnd = mglGetSecs;
        
        
    end % satellite actions
    
end % Loop over trials


%% Post trial loop actions

% Report that we are done with this block of trials
if (protocolParams.verbose), fprintf('- Done with block of trials.\n'); end

% Role dependent actions - BASE
if any(strcmp('base',myRoles))
    %  undo key listening
    ListenChar(0);
    % Put the trial information into the response struct
    responseStruct.events = events;
end

% Role dependent actions - SATELLITE
if any(strcmp('satellite',myRoles))
    responseStruct.events = events;
    responseStruct.data = dataStruct;
    responseStruct.protocolParams = protocolParams;
end


end % SquintTrialLoop function
