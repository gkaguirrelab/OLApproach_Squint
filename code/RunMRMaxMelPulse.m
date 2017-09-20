% RunMRMaxMelPulse
%
% Description:
%   Define the parameters for the MRMaxMelPulse protocol of the
%   OLApproach_TrialSequenceMR approach, and then invoke each of the
%   steps required to set up and run a session of the experiment.

% 6/28/17  dhb  Added first history comment.
%          dhb  Move params.photoreceptorClasses into the dictionaries.
%          dhb  Move params.useAmbient into the dictionaries.
% 09/20/17 dhb, gka, hmm  Copy over the CRF version and start editing.

%% Clear
clear; close all;

%% Set the parameter structure here
%
% Who we are and what we're doing today
protocolParams.approach = 'OLApproach_TrialSequenceMR';
protocolParams.protocol = 'MRMaxMelPulse';
protocolParams.protocolOutputName = 'MMP';
protocolParams.emailRecipient = 'jryan@mail.med.upenn.edu';
protocolParams.verbose = true;
protocolParams.simulate = true;

% Modulations used in this experiment
% 
% The set of arrays below should have the same length, the entries get paired.
%
% Do not change the order of these directions without also fixing up
% the Demo and Experimental programs, which are counting on this order.
%
% The first trial type has its contrast set to 0 below, and is a blank
% trial, despite the fact that you might think it involved a modulation.
protocolParams.modulationNames = {'MaxContrast3sSegment' ...
    'MaxContrast3sSegment' ...
    'MaxContrast3sSegment' ...
    'MaxContrast3sSegment' ...
    };
                              
protocolParams.directionNames = {...
    'MaxMel_275_80_667'...
    'MaxMel_275_80_667'...
    'MaxLMS_275_80_667'...
    'LightFlux_540_380_50'...
    };

% Flag as to whether to run the correction/validation at all for each direction.
% You set to true here entries for the unique directions, so as not
% to re-correct the same file more than once. This saves time.
protocolParams.doCorrectionFlag = {...
    false, ...
    true, ...
    true, ...
    true, ...
    };

% This is also related to directions.  This determines whether the 
% correction gets done using the radiometer (set to true) or just by
% simulation (just uses nominal spectra on each iteration of the correction.)
% Usually you will want all of these to be true, unless you've determined
% that for the particular box and directions you're working with you don't need
% the extra precision provided by spectrum correction.
protocolParams.directionsCorrect = [...
    false ...
    false ...
    false ...
    false ...
    ];

% Contrasts to use, relative to the powerLevel = 1 modulation in the
% directions file.
protocolParams.trialTypeParams = [...
    struct('contrast',0) ...
    struct('contrast',1) ...
    struct('contrast',1) ...
    struct('contrast',1) ...
    ];

% Field size and pupil size.
%
% These are used to construct photoreceptors for validation for directions
% (e.g. light flux) where they are not available in the direction file.
% They can also be used to check for consistency.  
%
% If we ever want to run with more than one field size and pupil size in a single 
% run, this will need a little rethinking.
protocolParams.fieldSizeDegrees = 60;
protocolParams.pupilDiameterMm = 8;

% Trial timing parameters.
%
% Trial duration - total time for each trial. 
protocolParams.trialDuration = 16;

% There is a minimum time at the start of each trial where
% the background is presented.  Then the actual trial
% start time is chosen based on a random draw from
% the jitter parameters.
protocolParams.trialBackgroundTimeSec = 0;
protocolParams.trialMinJitterTimeSec = 1;                  % Time before step
protocolParams.trialMaxJitterTimeSec = 3;                  % Phase shifts in seconds

% Set ISI time in seconds
protocolParams.isiTime = 0;                             

% Attention task parameters.
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
protocolParams.attentionTask = true;
protocolParams.attentionSegmentDuration = 16;
protocolParams.attentionEventDuration = 0.5;
protocolParams.attentionMarginDuration = 2;
protocolParams.attentionEventProb = 1;
protocolParams.postAllTrialsWaitForKeysTime = 1;
protocolParams.attentionEligibleTrialTypes = [1];

% Modulation and direction indices match on each trial, so we just specify
% them once in a single array.
%
% Need to add some checking that desired contrasts, frequencies and phases
% are available in the ModulationStartsStops file.  Not sure where this
% checking best happens.
%
% To make sense of all this, we need to understand OLModulationParamsDictionary fields,
% OLReceptorIsolateMakeModulationStartsStops, and possibly some of the other modulation
% routines.
protocolParams.trialTypeOrder = [randperm(6),randperm(6),randperm(6),randperm(6)];
protocolParams.nTrials = length(protocolParams.trialTypeOrder);
      
% OneLight parameters
protocolParams.boxName = 'BoxB';  
protocolParams.calibrationType = 'BoxBRandomizedLongCableDStubby1_ND00';
protocolParams.takeCalStateMeasurements = true;
protocolParams.takeTemperatureMeasurements = false;

% Validation parameters
protocolParams.nValidationsPerDirection = 2;

% Information we prompt for and related
commandwindow;
protocolParams.observerID = GetWithDefault('>> Enter <strong>user name</strong>', 'HERO_xxxx');
protocolParams.observerAgeInYrs = GetWithDefault('>> Enter <strong>observer age</strong>:', 32);
protocolParams.todayDate = datestr(now, 'yyyy-mm-dd');

%% Use these to test reporting on validation and spectrum seeking
%
% Spectrum Seeking: /MELA_data/Experiments/OLApproach_Psychophysics/DirectionCorrectedPrimaries/Jimbo/081117/session_1/...
% Validation: /MELA_data/Experiments/OLApproach_Psychophysics/DirectionValidationFiles/Jimbo/081117/session_1/...
% protocolParams.observerID = 'tired';
% protocolParams.observerAgeInYrs = 32;
% protocolParams.todayDate = '2017-09-01';
% protocolParams.sessionName = 'session_1';
% protocolParams.sessionLogDir = '/Users1/Dropbox (Aguirre-Brainard Lab)/MELA_data/Experiments/OLApproach_TrialSequenceMR/MRContrastResponseFunction/SessionRecords/michael/2017-09-01/session_1';
% protocolParams.fullFileName = '/Users1/Dropbox (Aguirre-Brainard Lab)/MELA_data/Experiments/OLApproach_TrialSequenceMR/MRContrastResponseFunction/SessionRecords/michael/2017-09-01/session_1/david_session_1.log';

%% Check that prefs are as expected, as well as some parameter sanity checks/adjustments
if (~strcmp(getpref('OneLightToolbox','OneLightCalData'),getpref(protocolParams.approach,'OneLightCalDataPath')))
    error('Calibration file prefs not set up as expected for an approach');
end

% Sanity check on modulations
if (length(protocolParams.modulationNames) ~= length(protocolParams.directionNames))
    error('Modulation and direction names cell arrays must have same length');
end

%% Open the OneLight
ol = OneLight('simulate',protocolParams.simulate); drawnow;

%% Let user get the radiometer set up
radiometerPauseDuration = 0;
ol.setAll(true);
commandwindow;
fprintf('- Focus the radiometer and press enter to pause %d seconds and start measuring.\n', radiometerPauseDuration);
input('');
ol.setAll(false);
pause(radiometerPauseDuration);

%% Open the session
%
% The call to OLSessionLog sets up info in protocolParams for where
% the logs go.
protocolParams = OLSessionLog(protocolParams,'OLSessionInit');

%% Make the corrected modulation primaries
OLMakeDirectionCorrectedPrimaries(ol,protocolParams,'verbose',protocolParams.verbose);
OLCheckPrimaryCorrection(protocolParams);

%% Make the modulation starts and stops
OLMakeModulationStartsStops(protocolParams.modulationNames,protocolParams.directionNames, protocolParams,'verbose',protocolParams.verbose);

%% Validate direction corrected primaries prior to experiemnt
OLValidateDirectionCorrectedPrimaries(ol,protocolParams,'Pre');
OLAnalyzeDirectionCorrectedPrimaries(protocolParams,'Pre');

%% Run demo code
%ModulationTrialSequenceMR.Demo(ol,protocolParams);

%% Run experiment
%
% Part of a protocol is the desired number of scans.  Calling the Experiment routine
% is for one scan.
ModulationTrialSequenceMR.Experiment(ol,protocolParams,'scanNumber',1,'verbose',protocolParams.verbose);

%% Let user get the radiometer set up
ol.setAll(true);
commandwindow;
fprintf('- Focus the radiometer and press enter to pause %d seconds and start measuring.\n', radiometerPauseDuration);
input('');
ol.setAll(false);
pause(radiometerPauseDuration);

%% Validate direction corrected primaries post experiment
OLValidateDirectionCorrectedPrimaries(ol,protocolParams,'Post');
OLAnalyzeDirectionCorrectedPrimaries(protocolParams,'Post');
