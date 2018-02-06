function [ protocolParams ] = getDefaultParams(varargin)

% admin stuff
protocolParams.approach = 'OLApproach_Squint';
protocolParams.protocol = 'SquintToPulse';
protocolParams.protocolOutputName = 'StP';
protocolParams.emailRecipient = 'jryan@mail.med.upenn.edu';
protocolParams.verbose = true;
protocolParams.setup = false;

% simulation
protocolParams.simulate.oneLight = false;
protocolParams.simulate.microphone = true;
protocolParams.simulate.speaker = true;
protocolParams.simulate.emg = true;
protocolParams.simulate.pupil = true;
protocolParams.simulate.udp = false;
protocolParams.simulate.observer = true;
protocolParams.simulate.operator = false;
protocolParams.simulate.makePlots = true;

% assign identities and roles to the various computers
protocolParams.hostNames = {'gka06', 'monkfish', 'gka33'};
protocolParams.hostIPs = {'128.91.59.227', '128.91.59.157', '128.91.59.228'};
protocolParams.hostRoles = {'base', 'satellite', 'satellite'};
protocolParams.hostActions = {{'operator','observer','oneLight'}, 'pupil', 'emg'};

% set some basics about our hardware
protocolParams.videoRecordSystemCommandStem='ffmpeg -hide_banner -video_size 1280x720 -framerate 60.000240 -f avfoundation -i "0" -c:v mpeg4 -q:v 1';
protocolParams.audioRecordObjCommand='audiorecorder(16000,8,1,2)';

% set up some information about our stimuli
protocolParams.modulationNames = { ...
    'MaxContrast4sPulse' ...
    'MaxContrast4sPulse' ...
    'MaxContrast4sPulse' ...
    'MaxContrast4sPulse' ...
    'MaxContrast4sPulse' ...
    'MaxContrast4sPulse' ...
    };
protocolParams.directionNames = {...
    'MaxMel_unipolar_275_60_667' ...
    'MaxMel_unipolar_275_60_667' ...
    'MaxMel_unipolar_275_60_667' ...
    'MaxLMS_unipolar_275_60_667'...
    'MaxLMS_unipolar_275_60_667'...
    'MaxLMS_unipolar_275_60_667'...
    };

% Flag as to whether to run the correction/validation at all for each direction.
% You set to true here entries for the unique directions, so as not
% to re-correct the same file more than once. This saves time.
%
% Note that, for obscure and boring reasons, the first entry in this cell array
% needs to be true.  That should never be a problem, because we always want to
% validate each direction once and only once, and it is as easy to validate the
% first occurrance of a direction as a subsequent one.

% the kind of spectrum seeking we actually will want to perform
protocolParams.doCorrectionAndValidationFlag = {...
    true, ...
    false, ...
    false, ...
    true, ...
    false, ...
    false, ...
    };

% This is also related to directions.  This determines whether the
% correction gets done using the radiometer (set to false) or just by
% simulation (set to true, just uses nominal spectra on each iteration of
% the correction.) Usually you will want all of these to be false, unless
% you've determined that for the particular box and directions you're
% working with you don't need the extra precision provided by spectrum
% correction.
protocolParams.correctBySimulation = [...
    false ...
    false ...
    false ...
    false ...
    false ...
    false ...
    ];

% set the contrast of each modulation
protocolParams.trialTypeParams = [...
    struct('contrast',1) ...
    struct('contrast',0.5) ...
    struct('contrast',0.25) ...
    struct('contrast',1) ...
    struct('contrast',0.25) ...
    struct('contrast',0.0625) ...
    ];

% pupil size and field of view
protocolParams.fieldSizeDegrees = 27.5;
protocolParams.pupilDiameterMm = 6;

% trial timing parameters
protocolParams.trialMinJitterTimeSec = 0.5;
protocolParams.trialMaxJitterTimeSec = 1.5;
protocolParams.trialBackgroundTimeSec = 1;
protocolParams.trialISITimeSec = 12;
protocolParams.trialResponseWindowTimeSec = 4;

% define lack of attention trials
protocolParams.attentionTask = false;

% which OneLight we're using
protocolParams.boxName = 'BoxA';
protocolParams.calibrationType = 'BoxARandomizedLongCableAEyePiece1_ND01';
protocolParams.takeCalStateMeasurements = true;
protocolParams.takeTemperatureMeasurements = false;

% Validation parameters
protocolParams.nValidationsPerDirection = 1;

end % end function