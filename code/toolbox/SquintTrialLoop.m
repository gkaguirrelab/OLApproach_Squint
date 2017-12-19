function [responseStruct, protocolParams] = SquintTrialLoop(protocolParams,stimulusStruct,ol,varargin)
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
%    stimulusStruct (struct)           Contains trial-by-trial starts/stops and other info.
%    ol (object)              An open OneLight object.
%
% Output:
%    responseStruct (struct)  Structure containing information about what happened on each trial
%    protocolParams (struct)  The protocol parameters structure.
%
% Optional key/value pairs:
%    verbose (logical)         true       Be chatty?

%% Set some local variables with values from the protocolParams
speakRateDefault = getpref(protocolParams.approach, 'SpeakRateDefault');


%% Initialize events variable and establish roles
events = struct;


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
if any(strcmp('base',protocolParams.myRoles))
    
    % Create and send an initial configuration packet between machines
    if protocolParams.simulate.udp
        if protocolParams.verbose
            fprintf('[simulate] base sending config packet via UDP\n');
        end
    else        
        % Construct a send a config packet to each satellite
        for ss = 1:numSatellites
            satelliteHostName = protocolParams.hostNames{satelliteIdx(ss)};

            configPacketFromBaseToSatellite = UDPobj.makePacket(...
                satelliteHostName,...                                               % satellite target
                [baseHostName ' -> ' satelliteHostName], ...                        % message direction
                'Acquisition parameters', ...                                       % message label
                'timeOutSecs', 0.7, ...                                             % Wait for 1 secs to receive this message. I'm the base so I'm impatient
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
                'displayPackets', protocolParams.verbose, ...
                'maxAttemptsNum', 10 ...
                );
        end
    end
    
    % Suppress keypresses going to the Matlab window and flush keyboard queue.
    %
    % This code is a curious mixture of PTB and mgl calls.  Not sure we need to
    % ListenChar(2), but not sure we don't.
    ListenChar(2);
    while (~isempty(mglGetKeyEvent)), end
    
    % Alert the observer that we are ready to start and wait for a keypress
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
if any(strcmp('satellite',protocolParams.myRoles))
    
    if protocolParams.simulate.udp
        % If we are in UDP simulation mode then the protocol params are
        % available as we are acting both as the base and the
        % satellite
        if protocolParams.verbose
            fprintf('[simulate] satellite receiving config packet via UDP\n');
        end
    else
        satelliteHostName = UDPBaseSatelliteCommunicator.getLocalHostName();
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
                'displayPackets', protocolParams.verbose, ...
                'maxAttemptsNum', 10 ...               
             );

        % Place the information from the message into protocolParams
        protocolParams.acquisitionNumber = theMessageReceived.data.acquisitionNumber;
        protocolParams.sessionName = theMessageReceived.data.sessionName;
        protocolParams.protocolOutputName = theMessageReceived.data.protocolOutputName;
        protocolParams.observerID = theMessageReceived.data.observerID;
        protocolParams.todayDate = theMessageReceived.data.todayDate;
    end
    
    % Determine if I am simulating any of my actions
    for aa = 1:length(protocolParams.myActions)
        if ischar(protocolParams.myActions{aa}) % A hack to handle the simulated actions for the base
            if protocolParams.simulate.(protocolParams.myActions{aa}) && protocolParams.simulate.makePlots
                responseStructFigHandle.(protocolParams.myActions{aa}) = figure();
                responseStructPlotHandle.(protocolParams.myActions{aa})=gca(responseStructFigHandle.(protocolParams.myActions{aa}));
            end
        end
    end
    
    % myAction specific commands
    if any(cellfun(@(x) sum(strcmp(x,'pupil')), protocolParams.myActions))
        % Create a directory in which to save pupil videos
        if protocolParams.setup
            pupilVideoSaveDirectoryPath = fullfile(getpref(protocolParams.protocol, 'DataFilesBasePath'),protocolParams.observerID, protocolParams.todayDate, protocolParams.sessionName, 'setup', sprintf('videoFiles_acquisition_%02d',protocolParams.acquisitionNumber));
        else
            pupilVideoSaveDirectoryPath = fullfile(getpref(protocolParams.protocol, 'DataFilesBasePath'),protocolParams.observerID, protocolParams.todayDate, protocolParams.sessionName, sprintf('videoFiles_acquisition_%02d',protocolParams.acquisitionNumber));
        end
        if ~exist(pupilVideoSaveDirectoryPath,'dir')
            mkdir(pupilVideoSaveDirectoryPath);
        end
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
        satelliteHostName = protocolParams.hostNames{satelliteIdx(ss)};
        satelliteAction = protocolParams.hostActions{satelliteIdx(ss)};
        trialPacketRootFromBase.(satelliteAction) = UDPobj.makePacket(...
            satelliteHostName,...                                               % satellite target
            [baseHostName ' -> ' satelliteHostName], ...                        % message direction
            'Parameters for this trial from base', ...                          % message label
            'timeOutSecs', 0.7, ...                                             % Wait for 1 secs to receive this message. I'm the base so I'm impatient
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
    if any(strcmp('base',protocolParams.myRoles))
                
        % Calculate how long the satellites should record data
        dataRecordingTimeSec = ...
            protocolParams.trialBackgroundTimeSec + ...
            stimulusStruct(trial).modulationData.modulationParams.stimulusDuration + ...
            protocolParams.trialISITimeSec;
        
        % Build the UDP communication packet for this trial for each
        % satellite
        if ~protocolParams.simulate.udp
            for ss = 1:length(satelliteIdx)
                satelliteAction = protocolParams.hostActions{satelliteIdx(ss)};
                trialPacketFromBase.(satelliteAction) = trialPacketRootFromBase.(satelliteAction);
                trialPacketFromBase.(satelliteAction).messageData.duration = ...
                    dataRecordingTimeSec;
                trialPacketFromBase.(satelliteAction).messageData.direction = ...
                    stimulusStruct(trial).modulationData.modulationParams.direction;
            end
        end
        
        % Create an audiorecording object
        if ~protocolParams.simulate.microphone
            audioRecObj = eval(protocolParams.audioRecordObjCommand);
        else
        end

        % Announce trial
        if (protocolParams.verbose)
            fprintf('* Start trial %i/%i - %s,\n', trial, protocolParams.nTrials, stimulusStruct(trial).modulationData.modulationParams.direction);
        end        

        % Alert the subject we are ready for the next trial
        if protocolParams.simulate.speaker
            if protocolParams.verbose
                fprintf('[simulate] base speaking we are ready for trial\n');
            end
        else
            Speak('Ready', [], speakRateDefault);
        end
        
        % Wait for button press from subject
        if protocolParams.simulate.observer
            if protocolParams.verbose
                fprintf('[simulate] Observer pressed a key\n');
            end
        else
            WaitForKeyPress
        end
                       
        % Speak which trial this is
        if protocolParams.simulate.speaker
            if protocolParams.verbose
                fprintf('[simulate] base speaking which trial we are on\n');
            end
        else
            Speak(['Trial ' num2str(trial)], [], speakRateDefault);
        end
                
        % Present the background spectrum
        events(trial).tTrialStart = mglGetSecs;
        ol.setMirrors(stimulusStruct(trial).modulationData.modulation.background.starts, stimulusStruct(trial).modulationData.modulation.background.stops);
        
        % Wait for jitter period
        jitterTimeSec  = protocolParams.trialMinJitterTimeSec + (protocolParams.trialMaxJitterTimeSec-protocolParams.trialMinJitterTimeSec).*rand(1);
        events(trial).jitterTimeSec = jitterTimeSec;
        mglWaitSecs(jitterTimeSec);

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
                    'displayPackets', protocolParams.verbose,...
                    'maxAttemptsNum', 10 ...
                    );
            end
            % Store the message information in the events struct
            events(trial).udpEvents.theMessageReceived = theMessageReceived;
            events(trial).udpEvents.theCommunicationStatus = theCommunicationStatus;
            events(trial).udpEvents.roundTripDelayMilliSecs = roundTripDelayMilliSecs;
            
            switch theCommunicationStatus
                case 'BAD_TRANSMISSION'
                    error('Received bad transmission status for packet');
                case 'NO_ACKNOWLDGMENT_WITHIN_TIMEOUT_PERIOD'
                    error('No response from the satellite to our packet');
                otherwise
                    % all is well
            end
        end

        % Record start time of the background.
        events(trial).tBackgroundStart = mglGetSecs;

        % Wait for the duration of the background period
        mglWaitSecs(protocolParams.trialBackgroundTimeSec);
                
        % Record start time of the stimulus.
        events(trial).tStimulusStart = mglGetSecs;

        % Present the modulation
        [events(trial).buffer, events(trial).t,  events(trial).counter] = ...
            SquintOLFlicker(ol, stimulusStruct, trial, stimulusStruct(trial).modulationData.modulationParams.timeStep, 1);
        
        % Put background back up and record times and keypresses.
        ol.setMirrors(stimulusStruct(trial).modulationData.modulation.background.starts, stimulusStruct(trial).modulationData.modulation.background.stops);
        events(trial).tStimulusEnd = mglGetSecs;
        
        % Wait for the duration of the ISI
        mglWaitSecs(protocolParams.trialISITimeSec);
        
        % Record start time of the stimulus.
        events(trial).tISIEnd = mglGetSecs;
        
        % We are now entering the response period. Start recording from the
        % microphone
        if protocolParams.simulate.microphone
            if protocolParams.verbose
                fprintf('[simulate] base recording from the microphone\n');
            end
        else
            record(audioRecObj,protocolParams.trialResponseWindowTimeSec);
        end

        % Play a beep to alert the subject that it is time to respond
        if protocolParams.simulate.speaker
            if protocolParams.verbose
                fprintf('[simulate] base alerting subject time to respond\n');
            end
        else
            t = linspace(0, 1, 2400);
            y = sin(160*2*pi*t)*0.5;
            sound(y, 16000);
        end
        
        % Wait for the duration of the response time. Could add in the
        % capability to record a keypress response from the subject if we
        % wished.        
        mglWaitSecs(protocolParams.trialResponseWindowTimeSec);

        % Play a boop to alert the subject that time is up
        if protocolParams.simulate.speaker
            if protocolParams.verbose
                fprintf('[simulate] base alerting subject response time is over\n');
            end
        else
            t = linspace(0, 1, 4800);
            y = sin(160*2*pi*t)*0.5;
            sound(y, 16000);
        end
        
        % Wait for the post-response time tone to play
        mglWaitSecs(4000/16000 * 2);
        
        % Save the audio recording and clear the audio object
        if protocolParams.simulate.microphone
            if protocolParams.verbose
                fprintf('[simulate] base saving audio data\n');
                dataStruct(trial).audio=NaN;
            end
        else
            dataStruct(trial).audio=getaudiodata(audioRecObj);
            clear audioRecObj
        end
        
    end % base actions
    
    
    % Role dependent actions - SATELLITE
    if any(strcmp('satellite',protocolParams.myRoles))
        
        % Wait for the trial packet from the base
        if protocolParams.simulate.udp
            theMessageReceived.data.duration = dataRecordingTimeSec;
            theMessageReceived.data.direction = stimulusStruct(trial).modulationData.modulationParams.direction;
            if protocolParams.verbose
                fprintf('[simulate] satellite received packet via UDP\n');
            end
            % Store the message information in the events struct
            events(trial).udpEvents.theMessageReceived = theMessageReceived;
            events(trial).udpEvents.theCommunicationStatus = 'simulated';
            events(trial).udpEvents.roundTripDelayMilliSecs = 'simulated';
        else
            [theMessageReceived, theCommunicationStatus, roundTripDelayMilliSecs] = ...
                UDPobj.communicate(trial, trialPacketForSatellite.(protocolParams.myActions{1}), ...
                'beVerbose', protocolParams.verbose, ...
                'displayPackets', protocolParams.verbose, ...
                'maxAttemptsNum', 10 ...
            );
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
        
        % ACTIONS -- emg
        if any(cellfun(@(x) sum(strcmp(x,'emg')), protocolParams.myActions))
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
        
        % ACTIONS -- pupil
        if any(cellfun(@(x) sum(strcmp(x,'pupil')), protocolParams.myActions))
            if protocolParams.simulate.pupil
                dataStruct(trial).pupil.videoRecordCommand = 'simulate ffmpeg recording command';
                dataStruct(trial).pupil.recordErrorFlag=0;
                dataStruct(trial).pupil.consoleOutput='simulate ffmpeg console output';
                if protocolParams.verbose
                    fprintf('[simulate] Video file recorded and saved\n');
                end
            else
                videoOutFile = fullfile(pupilVideoSaveDirectoryPath, sprintf('trial_%03d.avi',trial)); 
                videoRecordCommand = [protocolParams.videoRecordSystemCommandStem ' -t ' num2str(theMessageReceived.data.duration) ' "' videoOutFile '"'];
                [recordErrorFlag,consoleOutput]=system(videoRecordCommand);
                if recordErrorFlag
                    warning('Error reported during video acquisition');
                end
                dataStruct(trial).pupil.videoRecordCommand=videoRecordCommand;
                dataStruct(trial).pupil.recordErrorFlag=recordErrorFlag;
                dataStruct(trial).pupil.consoleOutput=consoleOutput;
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
if any(strcmp('base',protocolParams.myRoles))
    %  undo key listening
    ListenChar(0);
    % Put the trial information into the response struct
    responseStruct.events = events;
    responseStruct.data = dataStruct;
end

% Role dependent actions - SATELLITE
if any(strcmp('satellite',protocolParams.myRoles))
    responseStruct.events = events;
    responseStruct.data = dataStruct;
end


end % SquintTrialLoop function
