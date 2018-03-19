protocolParams.approach = 'OLApproach_Squint';
protocolParams.protocol = 'SquintToPulse';
protocolParams.protocolOutputName = 'StP';
protocolParams.emailRecipient = 'jryan@mail.med.upenn.edu';
protocolParams.verbose = true;
protocolParams.setup = false;
protocolParams.simulate.oneLight = false;
protocolParams.simulate.radiometer = true;
protocolParams.simulate.microphone = false;
protocolParams.simulate.speaker = false;
protocolParams.simulate.emg = false;
protocolParams.simulate.pupil = false;
protocolParams.simulate.udp = false;
protocolParams.simulate.observer = false;
protocolParams.simulate.operator = false;
protocolParams.simulate.makePlots = true;

% define the identities of the base computer (which oversees the
% experiment and controls the OneLight) and the satellite computers that
% handle EMG and pupil recording
%protocolParams.hostNames = {'gka06', 'gka33', 'monkfish'};
%protocolParams.hostIPs = {'128.91.59.227', '128.91.59.228', '128.91.59.157'};
%protocolParams.hostRoles = {'base', 'satellite', 'satellite'};
%protocolParams.hostActions = {{'operator','observer','oneLight'}, 'emg', 'pupil'};

% provide the basic command for video acquisition
% To determine which device to record from, issue thecommand
%       ffmpeg -f avfoundation -list_devices true -i ""
% in the terminal. Identify which device number we want, and place that in
% the quotes after the -i in the command stem below.
% GKA NOTE: do we also need the argument -pixel_format uyvy422  ?
protocolParams.videoRecordSystemCommandStem=['ffmpeg -hide_banner -video_size 1280x720 -pix_fmt uyvy422 -framerate 60.000240 -f avfoundation -i "0" -c:v mpeg4 -q:v 1'];
protocolParams.audioRecordObjCommand='audiorecorder(16000,8,1,2)';

% Establish myRole and myActions

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
protocolParams.calibrationType = 'BoxBShortLiquidLightGuideDEyePiece1_ND04';
protocolParams.takeCalStateMeasurements = true;
protocolParams.takeTemperatureMeasurements = false;

% Get calibration
calibration = OLGetCalibrationStructure('CalibrationType',protocolParams.calibrationType,'CalibrationDate','latest');

protocolParams.observerID = 'ageTest';

radiometer = [];
protocolParams.simulate.oneLight = true;

ol = OneLight('simulate',protocolParams.simulate.oneLight,'plotWhenSimulating',protocolParams.simulate.makePlots); drawnow;


    protocolParams.observerAgeInYrs = 25;

    
    % Make nominal directionStructs, containing nominal primaries
    % First we get the parameters for the directions from the dictionary
    MaxMelParams = OLDirectionParamsFromName('MaxMel_unipolar_275_60_667');
    MaxMelDirectionStruct = OLDirectionNominalStructFromParams(MaxMelParams, calibration, 'observerAge',protocolParams.observerAgeInYrs);
    
    MaxLMSParams = OLDirectionParamsFromName('MaxLMS_unipolar_275_60_667');
    MaxLMSDirectionStruct = OLDirectionNominalStructFromParams(MaxLMSParams, calibration, 'observerAge',protocolParams.observerAgeInYrs);
    
    LightFluxParams = OLDirectionParamsFromName('LightFlux_540_380_50');
    LightFluxDirectionStruct = OLDirectionNominalStructFromParams(LightFluxParams, calibration, 'observerAge',protocolParams.observerAgeInYrs);
    

    
    receptors = MaxLMSDirectionStruct.describe.directionParams.T_receptors;
    receptorStrings = MaxLMSDirectionStruct.describe.directionParams.photoreceptorClasses;
   for i = 1:1
        MaxMelDirectionStruct.describe.(sprintf('validatePre%d',i)) = OLValidateDirection(MaxMelDirectionStruct,calibration,ol,radiometer,...
            'receptors',receptors,'receptorStrings',receptorStrings);
        MaxLMSDirectionStruct.describe.(sprintf('validatePre%d',i)) = OLValidateDirection(MaxLMSDirectionStruct,calibration,ol,radiometer,...
            'receptors',receptors,'receptorStrings',receptorStrings);
        LightFluxDirectionStruct.describe.(sprintf('validatePre%d',i)) = OLValidateDirection(LightFluxDirectionStruct,calibration,ol,radiometer,...
            'receptors',receptors,'receptorStrings',receptorStrings);
    end
    
    % summarize validation
    if ~protocolParams.simulate.radiometer % only if we've actually validated
        melFig = figure;
        summarizeValidation(MaxMelDirectionStruct);
        LMSFig = figure;
        summarizeValidation(MaxLMSDirectionStruct);
        LightFluxFig = figure;
        summarizeValidation(LightFluxDirectionStruct);
    end
    

