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
%
% Who we are and what we're doing today
protocolParams.approach = 'OLApproach_Squint';
protocolParams.protocol = 'Screening';
protocolParams.protocolOutputName = 'Screening';
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
protocolParams.trialResponseWindowTimeSec = 0;
protocolParams.trialJitterRecordingDurationSec = 0.5;

protocolParams.nTrials = 6;

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


% OneLight parameters
protocolParams.boxName = 'BoxB';
protocolParams.calibrationType = 'BoxBShortLiquidLightGuideDEyePiece1_ND04';
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
    
    LightFluxParams = OLDirectionParamsFromName('LightFlux_540_380_50');
    [ LightFluxDirection, LightFluxBackground ] = OLDirectionNominalFromParams(LightFluxParams, calibration);
    %% Validate the direction objects before direction correction
    % Direction correction doesn't always seem to help, so if we can make good
    % directions without it then we'll just grab them
    T_receptors = MaxMelDirection.describe.directionParams.T_receptors; % the T_receptors will be the same for each direction, so just grab one
    for ii = 1:protocolParams.nValidationsPerDirection
        OLValidateDirection(MaxMelDirection, MaxMelBackground, ol, radiometer, 'receptors', T_receptors, 'label', 'precorrection');
        postreceptoralContrast = ComputePostreceptoralContrastsFromLMSContrasts(MaxMelDirection.describe.validation(ii).contrastActual(1:3,1));
        MaxMelDirection.describe.validation(ii).postreceptoralContrastActual = postreceptoralContrast;
        
        OLValidateDirection(MaxLMSDirection, MaxLMSBackground, ol, radiometer, 'receptors', T_receptors, 'label', 'precorrection');
        postreceptoralContrast = ComputePostreceptoralContrastsFromLMSContrasts(MaxLMSDirection.describe.validation(ii).contrastActual(1:3,1));
        MaxLMSDirection.describe.validation(ii).postreceptoralContrastActual = postreceptoralContrast;
        
        OLValidateDirection(LightFluxDirection, LightFluxBackground, ol, radiometer, 'receptors', T_receptors, 'label', 'precorrection');
        postreceptoralContrast = ComputePostreceptoralContrastsFromLMSContrasts(LightFluxDirection.describe.validation(ii).contrastActual(1:3,1));
        LightFluxDirection.describe.validation(ii).postreceptoralContrastActual = postreceptoralContrast;
    end
    
    %% Check if these nominal spectra meet exclusion criteria
    % if they don't (meaning the data can be included), we don't have to
    % correct the directions
    
    melFigure = figure;
    MelValidation = summarizeValidation(MaxMelDirection, 'whichValidationPrefix', 'precorrection');
    MelPassStatus = applyValidationExclusionCriteria(MelValidation, MaxMelDirection);
    
    LMSFigure = figure;
    LMSValidation = summarizeValidation(MaxLMSDirection, 'whichValidationPrefix', 'precorrection');
    LMSPassStatus = applyValidationExclusionCriteria(LMSValidation, MaxLMSDirection);
    
    LightFluxFigure = figure;
    LightFluxValidation = summarizeValidation(LightFluxDirection, 'whichValidationPrefix', 'precorrection');
    LightFluxPassStatus = applyValidationExclusionCriteria(LightFluxValidation, LightFluxDirection);
    
    
    %% Correct the direction objects
    % then validate
    
    %if MelPassStatus == 0
        OLCorrectDirection_oldSpectrumSeeking(MaxMelDirection, MaxMelBackground, ol, radiometer);
        for ii = length(MaxMelDirection.describe.validation)+1:length(MaxMelDirection.describe.validation)+protocolParams.nValidationsPerDirection
            OLValidateDirection(MaxMelDirection, MaxMelBackground, ol, radiometer, 'receptors', T_receptors, 'label', 'postcorrection');
            postreceptoralContrast = ComputePostreceptoralContrastsFromLMSContrasts(MaxMelDirection.describe.validation(ii).contrastActual(1:3,1));
            MaxMelDirection.describe.validation(ii).postreceptoralContrastActual = postreceptoralContrast;
        end
        melPostFigure = figure;
        MelPostValidation = summarizeValidation(MaxMelDirection, 'whichValidationPrefix', 'postcorrection', 'plot', 'off');
        MelPassStatus = applyValidationExclusionCriteria(MelPostValidation, MaxMelDirection);
        MelPostValidation = summarizeValidation(MaxMelDirection);
        
    %end
    
    %if LMSPassStatus == 0
        OLCorrectDirection_oldSpectrumSeeking(MaxLMSDirection, MaxLMSBackground, ol, radiometer);
        for ii = length(MaxLMSDirection.describe.validation)+1:length(MaxLMSDirection.describe.validation)+protocolParams.nValidationsPerDirection
            OLValidateDirection(MaxLMSDirection, MaxLMSBackground, ol, radiometer, 'receptors', T_receptors, 'label', 'postcorrection');
            postreceptoralContrast = ComputePostreceptoralContrastsFromLMSContrasts(MaxLMSDirection.describe.validation(ii).contrastActual(1:3,1));
            MaxLMSDirection.describe.validation(ii).postreceptoralContrastActual = postreceptoralContrast;
        end
        LMSPostFigure = figure;
        LMSPostValidation = summarizeValidation(MaxLMSDirection, 'whichValidationPrefix', 'postcorrection', 'plot', 'off');
        LMSPassStatus = applyValidationExclusionCriteria(LMSPostValidation, MaxLMSDirection);
        LMSPostValidation = summarizeValidation(MaxLMSDirection);
        
    %end
    
    %if MelLMSPassStatus == 0
        OLCorrectDirection_oldSpectrumSeeking(LightFluxDirection, LightFluxBackground, ol, radiometer);
        for ii = length(LightFluxDirection.describe.validation)+1:length(LightFluxDirection.describe.validation)+protocolParams.nValidationsPerDirection
            OLValidateDirection(LightFluxDirection, LightFluxBackground, ol, radiometer, 'receptors', T_receptors, 'label', 'postcorrection');
            postreceptoralContrast = ComputePostreceptoralContrastsFromLMSContrasts(LightFluxDirection.describe.validation(ii).contrastActual(1:3,1));
            LightFluxDirection.describe.validation(ii).postreceptoralContrastActual = postreceptoralContrast;
        end
        LightFluxPostFigure = figure;
        LightFluxPostValidation = summarizeValidation(LightFluxDirection, 'whichValidationPrefix', 'postcorrection', 'plot', 'off');
        LightFluxPassStatus = applyValidationExclusionCriteria(LightFluxPostValidation, LightFluxDirection);
        LightFluxPostValidation = summarizeValidation(LightFluxDirection);
        
    %end
    
%% Check that we have good modulations
if MelPassStatus == 1
    fprintf('Mel modulations are good\n');
else
    fprintf('<strong>Mel modulations are poor</strong>\n');
end

if LMSPassStatus == 1
    fprintf('LMS modulations are good\n');
else
    fprintf('<strong>LMS modulations are poor</strong>\n');
end

if LightFluxPassStatus == 1
    fprintf('Mel/LMS combined modulations are good\n');
else
    fprintf('<strong>Mel/LMS combined modulations are poor</strong>\n');
end
    
if LightFluxPassStatus == 1 && LMSPassStatus == 1 && MelLMSPassStatus == 1
    fprintf('***We have good modulations and are ready for the experiment***\n');
else
    fprintf('<strong>***Modulations are poor, we have to figure something out***</strong>\n');
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




for aa = startingAcquisitionNumber:1
    protocolParams.acquisitionNumber = aa;
    
    if any(cellfun(@(x) sum(strcmp(x,'oneLight')),protocolParams.myActions))
        
            protocolParams.trialTypeOrder = [1, 1, 4, 4, 7, 7];
        
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
    
    % Validate direction corrected primaries post experiment
    T_receptors = MaxMelLMSDirection.describe.directionParams.T_receptors; % the T_receptors will be the same for each direction, so just grab one
    for ii = length(MaxMelDirection.describe.validation)+1:length(MaxMelDirection.describe.validation)+protocolParams.nValidationsPerDirection
        OLValidateDirection(MaxMelDirection, MaxMelBackground, ol, radiometer, 'receptors', T_receptors, 'label', 'postexperiment');
        postreceptoralContrast = ComputePostreceptoralContrastsFromLMSContrasts(MaxMelDirection.describe.validation(ii).contrastActual(1:3,1));
        MaxMelDirection.describe.validation(ii).postreceptoralContrastActual = postreceptoralContrast;
    end
    
    for ii = length(MaxLMSDirection.describe.validation)+1:length(MaxLMSDirection.describe.validation)+protocolParams.nValidationsPerDirection
        
        OLValidateDirection(MaxLMSDirection, MaxLMSBackground, ol, radiometer, 'receptors', T_receptors, 'label', 'postexperiment');
        postreceptoralContrast = ComputePostreceptoralContrastsFromLMSContrasts(MaxLMSDirection.describe.validation(ii).contrastActual(1:3,1));
        MaxLMSDirection.describe.validation(ii).postreceptoralContrastActual = postreceptoralContrast;
    end
    for ii = length(MaxMelLMSDirection.describe.validation)+1:length(MaxMelLMSDirection.describe.validation)+protocolParams.nValidationsPerDirection
        
        OLValidateDirection(MaxMelLMSDirection, MaxMelLMSBackground, ol, radiometer, 'receptors', T_receptors, 'label', 'postexperiment');
        postreceptoralContrast = ComputePostreceptoralContrastsFromLMSContrasts(MaxMelLMSDirection.describe.validation(ii).contrastActual(1:3,1));
        MaxMelLMSDirection.describe.validation(ii).postreceptoralContrastActual = postreceptoralContrast;
    end
    savePath = fullfile(getpref('OLApproach_Squint', 'DataPath'), 'Experiments', protocolParams.approach, protocolParams.protocol, 'DirectionObjects', protocolParams.observerID, [protocolParams.todayDate, '_', protocolParams.sessionName]);
    if ~exist(savePath,'dir')
        mkdir(savePath);
    end
    save(fullfile(savePath, 'MaxMelDirection.mat'), 'MaxMelDirection');
    save(fullfile(savePath, 'MaxLMSDirection.mat'), 'MaxLMSDirection');
    save(fullfile(savePath, 'MaxMelLMSDirection.mat'), 'MaxMelLMSDirection');
end


% Role dependent actions - satellite
if any(cellfun(@(x) sum(strcmp(x,'satellite')),protocolParams.myRoles))
    if protocolParams.verbose
        for aa = 1:length(protocolParams.myActions)
            fprintf('Satellite is finished.\n')
        end
    end
end
