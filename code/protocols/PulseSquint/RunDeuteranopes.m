% RunSquintApproach
%
% Description:
%   Define the parameters for the RunSquintApproach protocol of the
%   OLApproach_Squint approach, and then invoke each of the
%   steps required to set up and run a session of the experiment.
%
% The design of these routines allows a single code base to operate on both
% the primary (base) computer that controls the timing of the experiment
% and the sitmuli, as well as the secondary (satellite) computers that
% collect EMG and pupil response data.

%% Clear
if exist('radiometer', 'var')
    try 
        radiometer.shutDown 
    end
end
clear; close all;

%% Set the parameter structure here

[ protocolParams ] = getDefaultParams('calibrationType', 'BoxALiquidShortCableDEyePiece1_ND02', ...
                                        'nTrials', 10, ...
                                        'protocol', 'Deuteranopes');

%% Pre-experiment actions: make nominal structs, correct the structs, validate the structs

% Set the ol variable to empty. It will be filled if we are the base.
ol = [];


% Role dependent actions - oneLight
if any(cellfun(@(x) sum(strcmp(x,'oneLight')),protocolParams.myActions))
    
    %% Open the OneLight
    [ modulationData, ol, radiometer, calibration, protocolParams ] = prepExperiment(protocolParams);
    
    % while the rest of subject prep continues, show the background of the
    % light flux stimuli through the eyepiece
    ol.setMirrors(modulationData(7).modulation.background.starts,modulationData(7).modulation.background.stops);
end
protocolParams.resume = false;


%% Pre-Flight Routine
% Set OneLight to background of lightFlux modulations for pupil calibration
% video
if any(cellfun(@(x) sum(strcmp(x,'oneLight')),protocolParams.myActions))
    if ~exist('ol', 'var')
            ol = OneLight('simulate',protocolParams.simulate.oneLight,'plotWhenSimulating',protocolParams.simulate.makePlots); drawnow;
            
        end
    if ~exist('modulationData', 'var')
            modulationData = [Mel400PulseModulationData; Mel200PulseModulationData; Mel100PulseModulationData; ...
                LMS400PulseModulationData; LMS200PulseModulationData; LMS100PulseModulationData; ...
                LightFlux400PulseModulationData; LightFlux200PulseModulationData; LightFlux100PulseModulationData];        
        end
    ol.setMirrors(modulationData(7).modulation.background.starts,modulationData(7).modulation.background.stops);
end
% Check the microphone
if any(cellfun(@(x) sum(strcmp(x,'base')),protocolParams.myRoles))
    micCheckDoneFlag = false;
    while ~micCheckDoneFlag
        micCheckChoice = GetWithDefault('>> Test the microphone? [y/n]', 'y');
        switch micCheckChoice
            case 'y'
                
                existingFig = findobj('type','figure','name','plotFig');
                close(existingFig);
                [plotFig] = testAudio(protocolParams);
            case 'n'
                micCheckDoneFlag = true;
                existingFig = findobj('type','figure','name','plotFig');
                close(existingFig);
            otherwise
        end
    end
end

% Check the video output
if any(cellfun(@(x) sum(strcmp(x,'pupil')),protocolParams.myActions))
    protocolParams = testVideo(protocolParams, 'label', 'pre');
end

% Check the EMG output
if any(cellfun(@(x) sum(strcmp(x,'emg')),protocolParams.myActions))
    emgCheckDoneFlag = false;
    while ~emgCheckDoneFlag
        emgCheckChoice = GetWithDefault('>> Test the EMG? [y/n]', 'y');
        switch emgCheckChoice
            case 'y'
                
                existingFig = findobj('type','figure','name','plotFig');
                close(existingFig);
                [plotFig] = testEMG(protocolParams);
            case 'n'
                emgCheckDoneFlag = true;
                existingFig = findobj('type','figure','name','plotFig');
                close(existingFig);
            otherwise
        end
    end
    
end

% Get the satelittes to the "ready to launch" position
if any(cellfun(@(x) sum(strcmp(x,'satellite')),protocolParams.myRoles))
    if protocolParams.verbose
        fprintf('Satellite is ready to launch.\n')
    end
end

%% Pause dropBox syncing
dropBoxSyncingStatus = pauseUnpauseDropbox('command', '--pause');
if protocolParams.verbose
    fprintf('DropBox syncing status set to %d\n',dropBoxSyncingStatus);
end

%% Pause BigFIx
%[status, result] = system('sudo /bin/launchctl unload /Library/LaunchDaemons/BESAgentDaemon.plist');

%% Run experiment

% check if we're starting a session from scratch, or resuming after a crash
% or with the same directionStructs
if (protocolParams.resume)
    % make sure the base has the information it needs to start the session
    if any(cellfun(@(x) sum(strcmp(x,'base')),protocolParams.myRoles))
        
        [ observerID, sessionName, mostRecentlyCompletedAcquisitionNumber ] = findMostRecentSession(protocolParams);
        if ~isfield(protocolParams, 'observerID')
            protocolParams.observerID = observerID;
        end
        %     if ~isfield(protocolParams, 'observerAge')
        %         protocolParams.acquisitionNumber = [];
        %     end
        if ~isfield(protocolParams, 'sessionName')
            protocolParams.sessionName = sessionName;
        end
        if ~isfield(protocolParams, 'acquisitionNumber')
            protocolParams.acquisitionNumber = mostRecentlyCompletedAcquisitionNumber+1;
        end
        
        % Information we prompt for and related
        commandwindow;
        protocolParams.observerID = GetWithDefault('>> Enter <strong>observer name</strong>', protocolParams.observerID);
        protocolParams.sessionName = GetWithDefault('>> Enter <strong>session number</strong>:', protocolParams.sessionName);
        protocolParams.acquisitionNumber = GetWithDefault('>> Enter <strong>acquisition number</strong>:', protocolParams.acquisitionNumber);
        protocolParams.todayDate = datestr(now, 'yyyy-mm-dd');
        
        protocolParams = OLSessionLog(protocolParams,'OLSessionInit');
        
        startingAcquisitionNumber = protocolParams.acquisitionNumber;
        
        % assemble the modulations into the modulationData variable
        if ~exist('modulationData', 'var')
            modulationData = [Mel1200PulseModulationData; Mel800PulseModulationData; Mel400PulseModulationData; ...
                LMS1200PulseModulationData; LMS800PulseModulationData; LMS400PulseModulationData; ...
                LightFlux1200PulseModulationData; LightFlux800PulseModulationData; LightFlux400PulseModulationData];        
        end
        
        if ~exist('ol', 'var')
            ol = OneLight('simulate',protocolParams.simulate.oneLight,'plotWhenSimulating',protocolParams.simulate.makePlots); drawnow;
            
        end
        
    end
    
    % make sure the satellites have the information they need about the
    % session
    if any(cellfun(@(x) sum(strcmp(x,'satellite')),protocolParams.myRoles))
        
        [ observerID, sessionName, mostRecentlyCompletedAcquisitionNumber ] = findMostRecentSession(protocolParams);
        
        % see if the acquisitionNumber is already in our protocolParams
        if ~isfield(protocolParams, 'acquisitionNumber')
            protocolParams.acquisitionNumber = mostRecentlyCompletedAcquisitionNumber+1;
        end
        
        protocolParams.acquisitionNumber = GetWithDefault('>> Enter <strong>acquisition number</strong>:', protocolParams.acquisitionNumber);
        
        ol = [];
        
        startingAcquisitionNumber = protocolParams.acquisitionNumber;
        if protocolParams.verbose
            fprintf('Satellite is ready to launch.\n')
        end
    end
    
else
    startingAcquisitionNumber = 1;
    
end

% clear out resume variable, so if we have to resume past this point we'll
% be prompted to get the subject information within this block
protocolParams.resume = true;

% instantiate UDP communication
% *** NEED TO SET PAUS HERE


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
    
lazyPollIntervalSeconds = 10/1000;
timeOutSecs = 50/1000;
maxAttemptsNum = 20;
UDPobj = UDPBaseSatelliteCommunicator.instantiateObject(protocolParams.hostNames, protocolParams.hostIPs, protocolParams.hostRoles, protocolParams.verbose, 'transmissionMode', 'SINGLE_BYTES');
UDPobj.lazyPollIntervalSeconds = lazyPollIntervalSeconds;

% Establish the communication
    triggerMessage = 'Go!';
    allSatellitesAreAGOMessage = 'All Satellites Are Go!';
    UDPobj.initiateCommunication(protocolParams.hostRoles,  protocolParams.hostNames, triggerMessage, allSatellitesAreAGOMessage, maxAttemptsNum, 'beVerbose', protocolParams.verbose);
    % Report success
    if protocolParams.verbose
        fprintf('UDP communication established\n');
    end
end




for aa = startingAcquisitionNumber:6
    protocolParams.acquisitionNumber = aa;
    
    if any(cellfun(@(x) sum(strcmp(x,'oneLight')),protocolParams.myActions))
        [ trialTypeOrder ] = makeTrialOrder(protocolParams);
        protocolParams.trialTypeOrder = trialTypeOrder;
        trialList = InitializeBlockStructArray(protocolParams,modulationData);
    else
        
        % if you're not the base controlling the onelight, you don't need a
        % real trialList
        trialList = [];
        
    end    
    
    ApproachEngine(ol,protocolParams, trialList, UDPobj, 'acquisitionNumber', aa, 'verbose',protocolParams.verbose);
end

%% Resume dropBox syncing
dropBoxSyncingStatus = pauseUnpauseDropbox('command','--resume');
if protocolParams.verbose
    fprintf('DropBox syncing status set to %d\n',dropBoxSyncingStatus);
end

%% Resume BigFix
%[status, result] = system('sudo /bin/launchctl load /Library/LaunchDaemons/BESAgentDaemon.plist');


%% Post-experiment actions

fprintf('Examine pupil videos to determine if we need to re-calibrate\n');
if any(cellfun(@(x) sum(strcmp(x,'pupil')),protocolParams.myActions))
    % have the option to run pupil calibration again, in case the subject was
% in a different position for the trials relative to the calibration
    testVideo(protocolParams, 'label', 'post');
end

% Role dependent actions - oneLightooc
if any(cellfun(@(x) sum(strcmp(x,'oneLight')),protocolParams.myActions))
    % perform post-experiment validation
    ol.setMirrors(modulationData(7).modulation.background.starts,modulationData(7).modulation.background.stops);
    if exist('radiometer', 'var')
        clear radiometer
    end
        
    if ~exist('radiometer', 'var')
        
        if ~protocolParams.simulate.radiometer
            radiometer = OLOpenSpectroRadiometerObj('PR-670');
        else
            radiometer = [];
        end
    end
    
    validatePostExperiment(protocolParams, ol, radiometer)
end


% Role dependent actions - satellite
if any(cellfun(@(x) sum(strcmp(x,'satellite')),protocolParams.myRoles))
    if protocolParams.verbose
        for aa = 1:length(protocolParams.myActions)
            fprintf('Satellite is finished.\n')
        end
    end
end
