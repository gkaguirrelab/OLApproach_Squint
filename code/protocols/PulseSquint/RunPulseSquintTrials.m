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
clear; close all;

%% Set the parameter structure here
%
% Who we are and what we're doing today
protocolParams.approach = 'OLApproach_Squint';
protocolParams.protocol = 'SquintToPulse';
protocolParams.protocolOutputName = 'StP';
protocolParams.emailRecipient = 'jryan@mail.med.upenn.edu';
protocolParams.verbose = true;
protocolParams.setup = false;
protocolParams.simulate.oneLight = true;
protocolParams.simulate.radiometer = true;
protocolParams.simulate.microphone = true;
protocolParams.simulate.speaker = true;
protocolParams.simulate.emg = true;
protocolParams.simulate.pupil = true;
protocolParams.simulate.udp = true;
protocolParams.simulate.observer = true;
protocolParams.simulate.operator = true;
protocolParams.simulate.makePlots = true;

% define the identities of the base computer (which oversees the
% experiment and controls the OneLight) and the satellite computers that
% handle EMG and pupil recording
protocolParams.hostNames = {'gka06', 'gka33', 'monkfish'};
protocolParams.hostIPs = {'128.91.59.227', '128.91.59.228', '128.91.59.157'};
protocolParams.hostRoles = {'base', 'satellite', 'satellite'};
protocolParams.hostActions = {{'operator','observer','oneLight'}, 'emg', 'pupil'};

% provide the basic command for video acquisition
% To determine which device to record from, issue thecommand
%       ffmpeg -f avfoundation -list_devices true -i ""
% in the terminal. Identify which device number we want, and place that in
% the quotes after the -i in the command stem below.
% GKA NOTE: do we also need the argument -pixel_format uyvy422  ?
protocolParams.videoRecordSystemCommandStem=['ffmpeg -hide_banner -video_size 1280x720 -pix_fmt uyvy422 -framerate 60.000240 -f avfoundation -i "0" -c:v mpeg4 -q:v 1'];
protocolParams.audioRecordObjCommand='audiorecorder(16000,8,1,2)';

% Establish myRole and myActions
if protocolParams.simulate.udp
    % If we are simulating the UDP connection stream, then we will operate
    % as the base and simulate the satellite component when needed.
    protocolParams.myRoles = {'base','satellite','satellite'};
    % If we are simulating the UDP connection stream, then we will execute
    % all actions in this routine.
    protocolParams.myActions = {{'operator','observer','oneLight'}, 'pupil', 'emg'};
    
else
    % Get local computer name
    localHostName = UDPBaseSatelliteCommunicator.getLocalHostName();
    % Find which hostName is contained within my computer name
    idxWhichHostAmI = find(cellfun(@(x) contains(localHostName, x), protocolParams.hostNames));
    if isempty(idxWhichHostAmI)
        error(['My local host name (' localHostName ') does not match an available host name']);
    end
    % Assign me the role corresponding to my host name
    protocolParams.myRoles = protocolParams.hostRoles{idxWhichHostAmI};
    if ~iscell(protocolParams.myRoles)
        protocolParams.myRoles={protocolParams.myRoles};
    end
    % Assign me the actions corresponding to my host name
    protocolParams.myActions = protocolParams.hostActions{idxWhichHostAmI};
    if ~iscell(protocolParams.myActions)
        protocolParams.myActions={protocolParams.myActions};
    end
end

% Field size and pupil size.
%
% These are used to construct photoreceptors for validation for directions
% (e.g. light flux) where they are not available in the direction file.
% They are checked for consistency with direction parameters that specify
% these fields in OLAnalyzeDirectionCorrectedPrimaries.
protocolParams.fieldSizeDegrees = 27.5;
protocolParams.pupilDiameterMm = 6;

% Trial timing parameters.
%
% A trial is composed of the following elements:
% - [trialMinJitterTimeSec, trialMaxJitterTimeSec] defines the bounds on a
%   uniform random distribution of time spent on the background prior to
%   trial initiation. A key property of the jitter period is that
%   physiologic data are not recorded during this interval. An audio alert
%   plays prior to the start of the jitter time.
% - trialBackgroundTimeSec - presentation of the background prior to the
%   stimulus. Physiologic recording begins with the onset of the
%   background period.
% - stimulusDuration - duration of the modulation itself. This is defined
%   by the stimulus dictionary
% - trialISITimeSec - duration of presentation of the background after the
%   stimulus. Physiologic recording ends at the end of the ISI time.
% - trialResponseWindowTimeSec - duration of a response window during which
%   the subject can make verbal or keypress responses. An audio alert plays
%   prior to the start of the response window.
%

protocolParams.trialMinJitterTimeSec = 0.5;
protocolParams.trialMaxJitterTimeSec = 1.5;
protocolParams.trialBackgroundTimeSec = 1;
protocolParams.trialISITimeSec = 12;
protocolParams.trialResponseWindowTimeSec = 4;
protocolParams.trialJitterRecordingDurationSec = 0.5;

protocolParams.nTrials = 10;

% Attention task parameters
%
% Currently, if you have an attention event then all trial types
% must have the same duration, and the attention event duration
% must match the trial duration.  These constraints could be relaxed
% by making the attentionSegmentDuration part of the trialType parameter
% set and by generalizing the way attention event information is generated
% within routine InitializeBlockStructArray.
%
% Also note that we assume that the dimming is visible when presented at
% any moment within any trial, even if the contrast is zero on that trial
% or it is a minimum contrast decrement, etc.  Would have to worry about how
% to handle this if that assumption is not valid.
protocolParams.attentionTask = false;

% Set trial sequence
%
% 12/12/17: these are now to be set within the loop around acquisition,
% because each acquisition will need to have a different trial order


% deBruijn sequences: we want to use deBruijn sequences to counter-balance
% the order of trial types within a given acquisition
deBruijnSequences = ...
    [3,     3,     1,     2,     1,     1,     3,     2,     2;
    3,     1,     2,     2,     1,     1,     3,     3,     2;
    2,     2,     3,     1,     1,     2,     1,     3,     3;
    2,     3,     3,     1,     1,     2,     2,     1,     3;
    3,     3,     1,     2,     1,     1,     3,     2,     2;
    3,     1,     2,     2,     1,     1,     3,     3,     2;
    2,     2,     3,     1,     1,     2,     1,     3,     3;
    2,     3,     3,     1,     1,     2,     2,     1,     3];
% each row here refers to a differnt deBruijn sequence governing trial
% order within each acquisition. Each different label refers (1, 2, or 3) to a
% different contrast level

% when it comes time to actually run an acquisition below, we'll grab a
% row from this deBruijnSequences matrix, and use that row to provide the
% trial order for that acqusition.


% OneLight parameters
protocolParams.boxName = 'BoxB';
protocolParams.calibrationType = 'BoxBRandomizedLongCableAEyePiece1_ND04';
protocolParams.takeCalStateMeasurements = true;
protocolParams.takeTemperatureMeasurements = false;

% Get calibration
calibration = OLGetCalibrationStructure('CalibrationType',protocolParams.calibrationType,'CalibrationDate','latest');

% Validation parameters
protocolParams.nValidationsPerDirection = 5;

%% Pre-experiment actions: make nominal structs, correct the structs, validate the structs

% Set the ol variable to empty. It will be filled if we are the base.
ol = [];

% Role dependent actions - base
if any(cellfun(@(x) sum(strcmp(x,'base')),protocolParams.myRoles))
    % Information we prompt for and related
    commandwindow;
    protocolParams.observerID = GetWithDefault('>> Enter <strong>observer name</strong>', 'HERO_xxxx');
    protocolParams.observerAgeInYrs = GetWithDefault('>> Enter <strong>observer age</strong>:', 32);
    protocolParams.sessionName = GetWithDefault('>> Enter <strong>session number</strong>:', 'session_1');
    protocolParams.todayDate = datestr(now, 'yyyy-mm-dd');
end

% Role dependent actions - oneLight
if any(cellfun(@(x) sum(strcmp(x,'oneLight')),protocolParams.myActions))
    
    %% Open the OneLight
    ol = OneLight('simulate',protocolParams.simulate.oneLight,'plotWhenSimulating',protocolParams.simulate.makePlots); drawnow;
    
    %% Let user get the radiometer set up
    if ~protocolParams.simulate.radiometer
        radiometerPauseDuration = 0;
        ol.setAll(true);
        commandwindow;
        fprintf('- Focus the radiometer and press enter to pause %d seconds and start measuring.\n', radiometerPauseDuration);
        input('');
        ol.setAll(false);
        pause(radiometerPauseDuration);
        radiometer = OLOpenSpectroRadiometerObj('PR-670');
    else
        radiometer = [];
    end
    
    %% Open the session
    %
    % The call to OLSessionLog sets up info in protocolParams for where
    % the logs go.
    protocolParams = OLSessionLog(protocolParams,'OLSessionInit');
    
    %% Make nominal direction objects, containing nominal primaries
    % First we get the parameters for the directions from the dictionary
    MaxMelParams = OLDirectionParamsFromName('MaxMel_unipolar_275_60_667');
    [ MaxMelDirection, MaxMelBackground ] = OLDirectionNominalFromParams(MaxMelParams, calibration, 'observerAge',protocolParams.observerAgeInYrs);
    
    
    MaxLMSParams = OLDirectionParamsFromName('MaxLMS_unipolar_275_60_667');
    [ MaxLMSDirection, MaxLMSBackground ] = OLDirectionNominalFromParams(MaxLMSParams, calibration, 'observerAge',protocolParams.observerAgeInYrs);
    
    MaxMelLMSParams = OLDirectionParamsFromName('MaxMelLMS_unipolar_275_60_667');
    [ MaxMelLMSDirection, MaxMelLMSBackground ] = OLDirectionNominalFromParams(MaxMelLMSParams, calibration, 'observerAge', protocolParams.observerAgeInYrs);
    %% Validate the direction objects before direction correction
    % Direction correction doesn't always seem to help, so if we can make good
    % directions without it then we'll just grab them
    T_receptors = MaxMelLMSDirection.describe.directionParams.T_receptors; % the T_receptors will be the same for each direction, so just grab one
    for ii = 1:protocolParams.nValidationsPerDirection
        OLValidateDirection(MaxMelDirection, MaxMelBackground, ol, radiometer, 'receptors', T_receptors, 'label', sprintf('precorrection_%d', ii));
        postreceptoralContrast = ComputePostreceptoralContrastsFromLMSContrasts(MaxMelDirection.describe.validation(ii).contrastActual(1:3,1));
        MaxMelDirection.describe.validation(ii).postreceptoralContrastActual = postreceptoralContrast;
        
        OLValidateDirection(MaxLMSDirection, MaxLMSBackground, ol, radiometer, 'receptors', T_receptors, 'label', sprintf('precorrection_%d', ii));
        postreceptoralContrast = ComputePostreceptoralContrastsFromLMSContrasts(MaxLMSDirection.describe.validation(ii).contrastActual(1:3,1));
        MaxLMSDirection.describe.validation(ii).postreceptoralContrastActual = postreceptoralContrast;
        
        OLValidateDirection(MaxMelLMSDirection, MaxMelLMSBackground, ol, radiometer, 'receptors', T_receptors, 'label', sprintf('precorrection_%d', ii));
        postreceptoralContrast = ComputePostreceptoralContrastsFromLMSContrasts(MaxMelLMSDirection.describe.validation(ii).contrastActual(1:3,1));
        MaxMelLMSDirection.describe.validation(ii).postreceptoralContrastActual = postreceptoralContrast;
    end
    
    %% Correct the direction objects
    OLCorrectDirection(MaxMelDirection, MaxMelBackground, ol, radiometer);
    OLCorrectDirection(MaxLMSDirection, MaxLMSBackground, ol, radiometer);
    OLCorrectDirection(MaxMelLMSDirection, MaxMelLMSBackground, ol, radiometer);
    
    %% Validate the direction objects after direction correction
    for ii = 1:protocolParams.nValidationsPerDirection
      OLValidateDirection(MaxMelDirection, MaxMelBackground, ol, radiometer, 'receptors', T_receptors, 'label', sprintf('postcorrection_%d', ii));
        postreceptoralContrast = ComputePostreceptoralContrastsFromLMSContrasts(MaxMelDirection.describe.validation(ii).contrastActual(1:3,1));
        MaxMelDirection.describe.validation(ii).postreceptoralContrastActual = postreceptoralContrast;
        
        OLValidateDirection(MaxLMSDirection, MaxLMSBackground, ol, radiometer, 'receptors', T_receptors, 'label', sprintf('postcorrection_%d', ii));
        postreceptoralContrast = ComputePostreceptoralContrastsFromLMSContrasts(MaxLMSDirection.describe.validation(ii).contrastActual(1:3,1));
        MaxLMSDirection.describe.validation(ii).postreceptoralContrastActual = postreceptoralContrast;
        
        OLValidateDirection(MaxMelLMSDirection, MaxMelLMSBackground, ol, radiometer, 'receptors', T_receptors, 'label', sprintf('postcorrection_%d', ii));
        postreceptoralContrast = ComputePostreceptoralContrastsFromLMSContrasts(MaxMelLMSDirection.describe.validation(ii).contrastActual(1:3,1));
        MaxMelLMSDirection.describe.validation(ii).postreceptoralContrastActual = postreceptoralContrast;
    end
    
    %% Save directionStructs
    savePath = fullfile(getpref('OLApproach_Squint', 'DataPath'), 'Experiments', protocolParams.approach, protocolParams.protocol, 'DirectionObjects', protocolParams.observerID, [protocolParams.todayDate, '_', protocolParams.sessionName]);
    if ~exist(savePath,'dir')
        mkdir(savePath);
    end
    save(fullfile(savePath, 'MaxMelDirection.mat'), 'MaxMelDirection');
    save(fullfile(savePath, 'MaxLMSDirection.mat'), 'MaxLMSDirection');
    save(fullfile(savePath, 'MaxMelLMSDirection.mat'), 'MaxMelLMSDirection');
    
    %% Make waveform
    waveformParams = OLWaveformParamsFromName('MaxContrastPulse'); % get generic pulse parameters
    waveformParams.stimulusDuration = 4; % 4 second pulses
    [Pulse400Waveform, pulseTimestep] = OLWaveformFromParams(waveformParams); % 4 second pulse waveform max contrast
    Pulse200Waveform = Pulse400Waveform / 2;
    Pulse100Waveform = Pulse400Waveform / 4;
    
    %% Make the modulation starts and stops
    Mel400PulseModulation = OLAssembleModulation([MaxMelBackground, MaxMelDirection], [ones(1, length(Pulse400Waveform)); Pulse400Waveform]);
    Mel200PulseModulation = OLAssembleModulation([MaxMelBackground, MaxMelDirection], [ones(1, length(Pulse200Waveform)); Pulse200Waveform]);
    Mel100PulseModulation = OLAssembleModulation([MaxMelBackground, MaxMelDirection], [ones(1, length(Pulse100Waveform)); Pulse100Waveform]);
    
    LMS400PulseModulation = OLAssembleModulation([MaxLMSBackground, MaxLMSDirection], [ones(1, length(Pulse400Waveform)); Pulse400Waveform]);
    LMS200PulseModulation = OLAssembleModulation([MaxLMSBackground, MaxLMSDirection], [ones(1, length(Pulse200Waveform)); Pulse200Waveform]);
    LMS100PulseModulation = OLAssembleModulation([MaxLMSBackground, MaxLMSDirection], [ones(1, length(Pulse100Waveform)); Pulse100Waveform]);
    
    MelLMS400PulseModulation = OLAssembleModulation([MaxMelLMSBackground, MaxMelLMSDirection], [ones(1, length(Pulse400Waveform)); Pulse400Waveform]);
    MelLMS200PulseModulation = OLAssembleModulation([MaxMelLMSBackground, MaxMelLMSDirection], [ones(1, length(Pulse200Waveform)); Pulse200Waveform]);
    MelLMS100PulseModulation = OLAssembleModulation([MaxMelLMSBackground, MaxMelLMSDirection], [ones(1, length(Pulse100Waveform)); Pulse100Waveform]);
    
    %% Define all modulations
    % Mel modulations
    Mel400PulseModulationData.modulationParams.direction = "Melanopsin 400% contrast";
    Mel400PulseModulationData.modulation = Mel400PulseModulation;
    [Mel400PulseModulationData.modulation.background.starts, Mel400PulseModulationData.modulation.background.stops] = OLPrimaryToStartsStops(MaxMelBackground.differentialPrimaryValues, calibration);
    Mel400PulseModulationData.modulationParams.stimulusDuration = waveformParams.stimulusDuration;
    Mel400PulseModulationData.modulationParams.timeStep = pulseTimestep;
    
    Mel200PulseModulationData.modulationParams.direction = "Melanopsin 200% contrast";
    Mel200PulseModulationData.modulation = Mel200PulseModulation;
    [Mel200PulseModulationData.modulation.background.starts, Mel200PulseModulationData.modulation.background.stops] = OLPrimaryToStartsStops(MaxMelBackground.differentialPrimaryValues, calibration);
    Mel200PulseModulationData.modulationParams.stimulusDuration = waveformParams.stimulusDuration;
    Mel200PulseModulationData.modulationParams.timeStep = pulseTimestep;
    
    Mel100PulseModulationData.modulationParams.direction = "Melanopsin 100% contrast";
    Mel100PulseModulationData.modulation = Mel100PulseModulation;
    [Mel100PulseModulationData.modulation.background.starts, Mel100PulseModulationData.modulation.background.stops] = OLPrimaryToStartsStops(MaxMelBackground.differentialPrimaryValues, calibration);
    Mel100PulseModulationData.modulationParams.stimulusDuration = waveformParams.stimulusDuration;
    Mel100PulseModulationData.modulationParams.timeStep = pulseTimestep;
    
    % LMS modulations
    LMS400PulseModulationData.modulationParams.direction = "LMS 400% contrast";
    LMS400PulseModulationData.modulation = LMS400PulseModulation;
    [LMS400PulseModulationData.modulation.background.starts, LMS400PulseModulationData.modulation.background.stops] = OLPrimaryToStartsStops(MaxLMSBackground.differentialPrimaryValues, calibration);
    LMS400PulseModulationData.modulationParams.stimulusDuration = waveformParams.stimulusDuration;
    LMS400PulseModulationData.modulationParams.timeStep = pulseTimestep;
    
    LMS200PulseModulationData.modulationParams.direction = "LMS 200% contrast";
    LMS200PulseModulationData.modulation = LMS200PulseModulation;
    [LMS200PulseModulationData.modulation.background.starts, LMS200PulseModulationData.modulation.background.stops] = OLPrimaryToStartsStops(MaxLMSBackground.differentialPrimaryValues, calibration);
    LMS200PulseModulationData.modulationParams.stimulusDuration = waveformParams.stimulusDuration;
    LMS200PulseModulationData.modulationParams.timeStep = pulseTimestep;
    
    LMS100PulseModulationData.modulationParams.direction = "LMS 100% contrast";
    LMS100PulseModulationData.modulation = LMS100PulseModulation;
    [LMS100PulseModulationData.modulation.background.starts, LMS100PulseModulationData.modulation.background.stops] = OLPrimaryToStartsStops(MaxLMSBackground.differentialPrimaryValues, calibration);
    LMS100PulseModulationData.modulationParams.stimulusDuration = waveformParams.stimulusDuration;
    LMS100PulseModulationData.modulationParams.timeStep = pulseTimestep;
    
    % Mel LMS Modulations
    MelLMS400PulseModulationData.modulationParams.direction = "Mel LMS 400% contrast";
    MelLMS400PulseModulationData.modulation = MelLMS400PulseModulation;
    [MelLMS400PulseModulationData.modulation.background.starts, MelLMS400PulseModulationData.modulation.background.stops] = OLPrimaryToStartsStops(MaxMelLMSBackground.differentialPrimaryValues, calibration);
    MelLMS400PulseModulationData.modulationParams.stimulusDuration = waveformParams.stimulusDuration;
    MelLMS400PulseModulationData.modulationParams.timeStep = pulseTimestep;
    
    MelLMS200PulseModulationData.modulationParams.direction = "Mel LMS 200% contrast";
    MelLMS200PulseModulationData.modulation = MelLMS200PulseModulation;
    [MelLMS200PulseModulationData.modulation.background.starts, MelLMS200PulseModulationData.modulation.background.stops] = OLPrimaryToStartsStops(MaxMelLMSBackground.differentialPrimaryValues, calibration);
    MelLMS200PulseModulationData.modulationParams.stimulusDuration = waveformParams.stimulusDuration;
    MelLMS200PulseModulationData.modulationParams.timeStep = pulseTimestep;
    
    MelLMS100PulseModulationData.modulationParams.direction = "Mel LMS 100% contrast";
    MelLMS100PulseModulationData.modulation = MelLMS100PulseModulation;
    [MelLMS100PulseModulationData.modulation.background.starts, MelLMS100PulseModulationData.modulation.background.stops] = OLPrimaryToStartsStops(MaxMelLMSBackground.differentialPrimaryValues, calibration);
    MelLMS100PulseModulationData.modulationParams.stimulusDuration = waveformParams.stimulusDuration;
    MelLMS100PulseModulationData.modulationParams.timeStep = pulseTimestep;
    
    % save modulations
    savePath = fullfile(getpref('OLApproach_Squint', 'DataPath'), 'Experiments', protocolParams.approach, protocolParams.protocol, 'ModulationStructs', protocolParams.observerID, protocolParams.todayDate);
    if ~exist(savePath,'dir')
        mkdir(savePath);
    end
    save(fullfile(savePath, 'Mel400PulseModulationData.mat'), 'Mel400PulseModulationData');
    save(fullfile(savePath, 'Mel200PulseModulationData.mat'), 'Mel200PulseModulationData');
    save(fullfile(savePath, 'Mel100PulseModulationData.mat'), 'Mel100PulseModulationData');
    
    save(fullfile(savePath, 'LMS400PulseModulationData.mat'), 'LMS400PulseModulationData');
    save(fullfile(savePath, 'LMS200PulseModulationData.mat'), 'LMS200PulseModulationData');
    save(fullfile(savePath, 'LMS100PulseModulationData.mat'), 'LMS100PulseModulationData');
    
    save(fullfile(savePath, 'MelLMS400PulseModulationData.mat'), 'MelLMS400PulseModulationData');
    save(fullfile(savePath, 'MelLMS200PulseModulationData.mat'), 'MelLMS200PulseModulationData');
    save(fullfile(savePath, 'MelLMS100PulseModulationData.mat'), 'MelLMS100PulseModulationData');
    ol.setMirrors(MelLMS400PulseModulationData.modulation.background.starts, MelLMS400PulseModulationData.modulation.background.stops);
end

%% Pre-Flight Routine

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
    testVideo(protocolParams);
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

resume = 0;
%% Run experiment

% check if we're starting a session from scratch, or resuming after a crash
% or with the same directionStructs
if resume ~= 0
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
        %protocolParams.observerAgeInYrs = GetWithDefault('>> Enter <strong>observer age</strong>:', protocolParams.observerAgeInYrs);
        protocolParams.sessionName = GetWithDefault('>> Enter <strong>session number</strong>:', protocolParams.sessionName);
        protocolParams.acquisitionNumber = GetWithDefault('>> Enter <strong>acquisition number</strong>:', protocolParams.acquisitionNumber);
        protocolParams.todayDate = datestr(now, 'yyyy-mm-dd');
        
        protocolParams = OLSessionLog(protocolParams,'OLSessionInit');
        
        startingAcquisitionNumber = protocolParams.acquisitionNumber;
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
resume = 1;

triplets = ...
    {'Mel', 'LMS', 'LightFlux'; ...
    'Mel', 'LightFlux', 'LMS'; ...
    'LightFlux', 'Mel', 'LMS'; ...
    'LightFlux', 'LMS', 'Mel'; ...
    'LMS', 'Mel', 'LightFlux'; ...
    'LMS', 'LightFlux', 'Mel';};

if any(cellfun(@(x) sum(strcmp(x,'oneLight')),protocolParams.myActions))
    if strcmp(protocolParams.sessionName, 'session_1')
        acquisitionOrder = [triplets(1,:), triplets(2,:)];
        
    elseif strcmp(protocolParams.sessionName, 'session_2')
        acquisitionOrder = [triplets(3,:), triplets(4,:)];
        
    elseif strcmp(protocolParams.sessionName, 'session_3')
        acquisitionOrder = [triplets(5,:), triplets(6,:)];
        
    elseif strcmp(protocolParams.sessionName, 'session_4')
        acquisitionOrder = [triplets(1,:), triplets(2,:)];
        
    end
    % set up some counters, so we know which deBruijn sequence to grab for the
    % relevant acquisition
    nMelAcquisitions = 1;
    nLMSAcquisitions = 1;
    nLightFluxAcquisitions = 1;
end




for aa = startingAcquisitionNumber:6
    protocolParams.acquisitionNumber = aa;
    
    if any(cellfun(@(x) sum(strcmp(x,'oneLight')),protocolParams.myActions))
        if strcmp(acquisitionOrder{aa}, 'Mel') % If the acqusition is Mel
            % grab a specific deBruijn sequence, and append a duplicate of the
            % last trial as the first trial
            protocolParams.trialTypeOrder = [deBruijnSequences(nMelAcquisitions,length(deBruijnSequences(nMelAcquisitions,:))), deBruijnSequences(nMelAcquisitions,:)];
            % update the counter
            nMelAcquisitions = nMelAcquisitions + 1;
        elseif strcmp(acquisitionOrder{aa}, 'LMS')
            % grab a specific deBruijn sequence, and append a duplicate of the
            % last trial as the first trial
            % the +3 gives LMS modulations, rather than Mel modulations (the
            % order of modulations is 1-3 is Mel, 4-6 is LMS, and 7-9 is light
            % flux)
            protocolParams.trialTypeOrder = [deBruijnSequences(nLMSAcquisitions,length(deBruijnSequences(nLMSAcquisitions,:)))+3, deBruijnSequences(nLMSAcquisitions,:)+3];
            %update the counter
            nLMSAcquisitions = nLMSAcquisitions + 1;
        elseif strcmp(acquisitionOrder{aa}, 'LightFlux')
            % grab a specific deBruijn sequence, and append a duplicate of the
            % last trial as the first trial
            % the +3 gives LMS modulations, rather than Mel modulations (the
            % order of modulations is 1-3 is Mel, 4-6 is LMS, and 7-9 is light
            % flux)
            protocolParams.trialTypeOrder = [deBruijnSequences(nLightFluxAcquisitions,length(deBruijnSequences(nLightFluxAcquisitions,:)))+6, deBruijnSequences(nLightFluxAcquisitions,:)+6];
            %update the counter
            nLightFluxAcquisitions = nLightFluxAcquisitions + 1;
        end
        
        % Put together the block struct array.
        % This describes what happens on each trial of the session.
        % Concatenate
        modulationData = [Mel400PulseModulationData; Mel200PulseModulationData; Mel100PulseModulationData; ...
            LMS400PulseModulationData; LMS200PulseModulationData; LMS100PulseModulationData; ...
            MelLMS400PulseModulationData; MelLMS200PulseModulationData; MelLMS100PulseModulationData];
        trialList = InitializeBlockStructArray(protocolParams,modulationData);
    else
        
        % if you're not the base controlling the onelight, you don't need a
        % real trialList
        trialList = [];
    end
    
    % the base computer needs to know more information than the satellites
    % do -- what modulation to give for each trial, for example. Since the
    % satellites don't need to know all of this, and in fact would require
    % some additional input (like session_number), we're going to give the
    % satellites the minimal amount of information they need to run
    % this means some stuff has to be hard-coded: nTrials, below; and the
    % number of acquisitions in a given session (hard-coded at the start of
    % the for-loop)
    protocolParams.nTrials = 10;
    
    
    
    ApproachEngine(ol,protocolParams, trialList,'acquisitionNumber', aa, 'verbose',protocolParams.verbose);
end

%% Resume dropBox syncing
dropBoxSyncingStatus = pauseUnpauseDropbox('command','--resume');
if protocolParams.verbose
    fprintf('DropBox syncing status set to %d\n',dropBoxSyncingStatus);
end


%% Post-experiment actions

% Role dependent actions - oneLight
if any(cellfun(@(x) sum(strcmp(x,'oneLight')),protocolParams.myActions))
    % Let user get the radiometer set up
    ol.setAll(true);
    commandwindow;
    fprintf('- Focus the radiometer and press enter to pause %d seconds and start measuring.\n', radiometerPauseDuration);
    input('');
    ol.setAll(false);
    pause(radiometerPauseDuration);
    
    %% Validate direction corrected primaries post experiment
    OLValidateDirectionCorrectedPrimaries(ol,protocolParams,'Post');
    OLAnalyzeDirectionCorrectedPrimaries(protocolParams,'Post');
end

% Role dependent actions - satellite
if any(cellfun(@(x) sum(strcmp(x,'satellite')),protocolParams.myRoles))
    if protocolParams.verbose
        for aa = 1:length(protocolParams.myActions)
            fprintf('Satellite is finished.\n')
        end
    end
end
