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
protocolParams.hostNames = {'gka06', 'monkfish', 'gka33'};
protocolParams.hostIPs = {'128.91.59.227', '128.91.59.157', '128.91.59.228'};
protocolParams.hostRoles = {'base', 'satellite', 'satellite'};
protocolParams.hostActions = {{'operator','observer','oneLight'}, 'pupil', 'emg'};

% provide the basic command for video acquisition
% To determine which device to record from, issue thecommand
%       ffmpeg -f avfoundation -list_devices true -i ""
% in the terminal. Identify which device number we want, and place that in
% the quotes after the -i in the command stem below.
% GKA NOTE: do we also need the argument -pixel_format uyvy422  ?
protocolParams.videoRecordSystemCommandStem='ffmpeg -hide_banner -video_size 1280x720 -pix_fmt uyvy422 -copyts -framerate 60.000240 -f avfoundation -i "0" -c:v mpeg4 -q:v 1';
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

%% Field size and pupil size.
%
% These are used to construct photoreceptors for validation for directions
% (e.g. light flux) where they are not available in the direction file.
% They are checked for consistency with direction parameters that specify
% these fields in OLAnalyzeDirectionCorrectedPrimaries.
protocolParams.fieldSizeDegrees = 27.5;
protocolParams.pupilDiameterMm = 6;

%% Trial timing parameters.
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

%% Attention task parameters
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

%% Set trial sequence
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


%% OneLight parameters
protocolParams.boxName = 'BoxB';
protocolParams.calibrationType = 'BoxBRandomizedLongCableBEyePiece2_ND01';
protocolParams.takeCalStateMeasurements = true;
protocolParams.takeTemperatureMeasurements = false;

% Get calibration
calibration = OLGetCalibrationStructure('CalibrationType',protocolParams.calibrationType,'CalibrationDate','latest');

% Validation parameters
protocolParams.nValidationsPerDirection = 5;

%% Pre-experiment actions

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
    
    %% Make nominal directionStructs, containing nominal primaries
    % First we get the parameters for the directions from the dictionary
    MaxMelParams = OLDirectionParamsFromName('MaxMel_unipolar_275_60_667');
    MaxMelDirectionStruct = OLDirectionNominalStructFromParams(MaxMelParams, calibration, 'observerAge',protocolParams.observerAgeInYrs);
    
    MaxLMSParams = OLDirectionParamsFromName('MaxLMS_unipolar_275_60_667');
    MaxLMSDirectionStruct = OLDirectionNominalStructFromParams(MaxLMSParams, calibration, 'observerAge',protocolParams.observerAgeInYrs);
    
    LightFluxParams = OLDirectionParamsFromName('LightFlux_540_380_50');
    LightFluxDirectionStruct = OLDirectionNominalStructFromParams(LightFluxParams, calibration, 'observerAge',protocolParams.observerAgeInYrs);
    
    %% Correct the directionStructs, containing corrected primaries
    MaxMelDirectionStruct = OLCorrectDirection(MaxMelDirectionStruct,calibration,ol,radiometer);
    %save(filename,'MaxMelDirectionStruct')
    MaxLMSDirectionStruct = OLCorrectDirection(MaxLMSDirectionStruct,calibration,ol,radiometer);
    
    LightFluxDirectionStruct = OLCorrectDirection(LightFluxDirectionStruct,calibration,ol,radiometer);
    
    
    %% Validate the directionStructs
    receptors = MaxMelDirectionStruct.describe.nominal.directionParams.T_receptors;
    receptorStrings = MaxMelDirectionStruct.describe.nominal.directionParams.photoreceptorClasses;
    for i = 1:protocolParams.nValidationsPerDirection
        MaxMelDirectionStruct.describe.(sprintf('validatePre%d',i)) = OLValidateDirection(MaxMelDirectionStruct,calibration,ol,radiometer,...
            'receptors',receptors,'receptorStrings',receptorStrings);
        MaxLMSDirectionStruct.describe.(sprintf('validatePre%d',i)) = OLValidateDirection(MaxLMSDirectionStruct,calibration,ol,radiometer,...
            'receptors',receptors,'receptorStrings',receptorStrings);
        LightFluxDirectionStruct.describe.(sprintf('validatePre%d',i)) = OLValidateDirection(LightFluxDirectionStruct,calibration,ol,radiometer,...
            'receptors',receptors,'receptorStrings',receptorStrings);
    end
    
    %% Make waveform
    waveformParams = OLWaveformParamsFromName('MaxContrastPulse'); % get generic pulse parameters
    waveformParams.stimulusDuration = 4; % 4 second pulses
    [Pulse400Waveform, pulseTimestep] = OLWaveformFromParams(waveformParams); % 4 second pulse waveform max contrast
    Pulse200Waveform = Pulse400Waveform / 2;
    Pulse100Waveform = Pulse400Waveform / 4;
    
    %% Make the modulation starts and stops
    Mel400PulseModulation = OLAssembleModulation(MaxMelDirectionStruct, Pulse400Waveform, calibration);
    [Mel400PulseModulation.background.starts, Mel400PulseModulation.background.stops] = OLPrimaryToStartsStops(Mel400PulseModulation.primaryValues(:,1), calibration);

    LMS400PulseModulation = OLAssembleModulation(MaxLMSDirectionStruct, Pulse400Waveform, calibration);
    [LMS400PulseModulation.background.starts, LMS400PulseModulation.background.stops] = OLPrimaryToStartsStops(LMS400PulseModulation.primaryValues(:,1), calibration);

    LightFlux400PulseModulation = OLAssembleModulation(LightFluxDirectionStruct, Pulse400Waveform, calibration);
    [LightFlux400PulseModulation.background.starts, LightFlux400PulseModulation.background.stops] = OLPrimaryToStartsStops(LightFlux400PulseModulation.primaryValues(:,1), calibration);
    
 %% Define all modulations
    % Mel modulations
    Mel400PulseModulationData.modulationParams.direction = "Melanopsin 400% contrast";
    Mel400PulseModulationData.modulation = Mel400PulseModulation;
    Mel400PulseModulationData.modulationParams.stimulusDuration = waveformParams.stimulusDuration;
    Mel400PulseModulationData.modulationParams.timeStep = pulseTimestep;
    
    % LMS modulations
    LMS400PulseModulationData.modulationParams.direction = "LMS 400% contrast";
    LMS400PulseModulationData.modulation = LMS400PulseModulation;
    LMS400PulseModulationData.modulationParams.stimulusDuration = waveformParams.stimulusDuration;
    LMS400PulseModulationData.modulationParams.timeStep = pulseTimestep;

    % Light Flux Modulations
    LightFlux400PulseModulationData.modulationParams.direction = "Light Flux 400% contrast";
    LightFlux400PulseModulationData.modulation = LightFlux400PulseModulation;
    LightFlux400PulseModulationData.modulationParams.stimulusDuration = waveformParams.stimulusDuration;
    LightFlux400PulseModulationData.modulationParams.timeStep = pulseTimestep;
   
    % Concatenate
    modulationData = [Mel400PulseModulationData; LMS400PulseModulationData; LightFlux400PulseModulationData];
end

protocolParams.acquisitionNumber = 1;
%% Run experiment
nAcquisitions = 100;

startingAcquisitionNumber = protocolParams.acquisitionNumber;
for aa = startingAcquisitionNumber:nAcquisitions
    protocolParams.acquisitionNumber = aa;
    fprintf('\n')
    for dd = 1:length(modulationData)
        fprintf('%d: %s \n', dd, modulationData(dd).modulationParams.direction)
    end
    fprintf('\n')
    fprintf('\n')
    protocolParams.trialTypeOrder = GetWithDefault('>> Enter <strong>trial type</strong>', 1);
    
    protocolParams.nTrials = 1;
    trialList = InitializeBlockStructArray(protocolParams,modulationData);
    ApproachEngine(ol,protocolParams, trialList,'acquisitionNumber', protocolParams.acquisitionNumber,'verbose',protocolParams.verbose);
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
