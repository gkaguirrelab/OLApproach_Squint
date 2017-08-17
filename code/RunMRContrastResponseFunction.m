% RunMRContrastResponseFunction
%
% Description:
%   Define the parameters for the MRContrastResponseFunctionprotocol of the
%   OLApproach_TrialSequenceMR approach, and then invoke each of the
%   steps required to set up and run a session of the experiment.

% 6/28/17  dhb  Added first history comment.
%          dhb  Move params.photoreceptorClasses into the dictionaries.
%          dhb  Move params.useAmbient into the dictionaries.

%% Clear
clear; close all;

%% Set the parameter structure here
%
% Who we are and what we're doing today
protocolParams.approach = 'OLApproach_TrialSequenceMR';
protocolParams.protocol = 'MRContrastResponseFunction';
protocolParams.protocolOutputName = 'CRF';
protocolParams.emailRecipient = 'jryan@mail.med.upenn.edu';
protocolParams.verbose = true;
protocolParams.simulate = true;

% Modulations used in this experiment
% 
% Thee four arrays below should have the same length, the entries get paired.
%
% Do not change the order of these directions without also fixing up
% the Demo and Experimental programs, which are counting on this order.
%
% [DHB NOTE: DON'T NECESSARILY WANT TO VALIDATE ALL TYPES, BECAUSE SHARE SAME
% MODULATION AND DIRECTION.  REALLY, JUST WANT TO VALIDATE EACH UNIQUE DIRECTION.
% THINK ABOUT THIS A LITTLE.  PROBABLY JUST WANT TO DO UNIQUE DIRECTIONS IN
% THE VALIDATION ROUTINE.  OR PASS A SEPARATE LIST OF DIRECTIONS TO VALIDATE
% TO THAT ROUTINE.]
protocolParams.modulationNames = {'MaxContrast3sSinusoid' ...
                                  'MaxContrast3sSinusoid' ...
                                  'MaxContrast3sSinusoid' ...
                                  'MaxContrast3sSinusoid' ...
                                  'MaxContrast3sSinusoid' ...
                                  'MaxContrast3sSinusoid' ...
                                  };
protocolParams.directionNames = {...
    'LightFlux_330_330_20'...
    'LightFlux_330_330_20'...
    'LightFlux_330_330_20'...
    'LightFlux_330_330_20'...
    'LightFlux_330_330_20'...
    'LightFlux_330_330_20'...
    };
protocolParams.trialTypeParams = [...0 5 10 20 40 80
    struct('contrast',0.8) ...
    struct('contrast',0.4) ...
    struct('contrast',0.2) ...
    struct('contrast',0.1) ...
    struct('contrast',0.05) ...
    struct('contrast',0.0) ...
    ];
protocolParams.directionsCorrect = [...
    true ...
    true ...
    true ...
    true ...
    true ...
    true ...
    ];

% Trial timing parameters.
%
% Trial duration - total time for each trial. 
protocolParams.trialDuration = 12;

% There is a minimum time at the start of each trial where
% the background is presented.  Then the actual trial
% start time is chosen based on a random draw from
% the jitter parameters.
protocolParams.trialBackgroundTimeSec = 1;
protocolParams.trialMinJitterTimeSec = 0;                  % Time before step
protocolParams.trialMaxJitterTimeSec = 3;                % Phase shifts in seconds

% Set ISI time in seconds
protocolParams.isiTime = 4.5;                             

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
protocolParams.attentionSegmentDuration = 3;
protocolParams.attentionEventDuration = 0.1;
protocolParams.attentionMarginDuration = 0.2;
protocolParams.attentionEventProb = 1/3;
protocolParams.postAllTrialsWaitForKeysTime = 1;

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
protocolParams.trialTypeOrder = [1 2 3 4 5 6];
protocolParams.nTrials = length(protocolParams.trialTypeOrder);
      
% OneLight parameters
protocolParams.boxName = 'BoxB';  
protocolParams.calibrationType = 'BoxBRandomizedLongCableBEyePiece1_ND03';
protocolParams.takeCalStateMeasurements = true;
protocolParams.takeTemperatureMeasurements = true;

% Validation parameters
protocolParams.nValidationsPerDirection = 2;

% Information we prompt for and related
commandwindow;
protocolParams.observerID = GetWithDefault('>> Enter <strong>user name</strong>', 'HERO_xxxx');
protocolParams.observerAgeInYrs = GetWithDefault('>> Enter <strong>observer age</strong>:', 32);
protocolParams.todayDate = datestr(now, 'mmddyy');

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
% OLAnalyzeValidationReceptorIsolate(validationPath, 'short');
% % Compute and print out information about the quality of
% % the current measurement, in contrast terms.
% theCanonicalPhotoreceptors = cacheData.data(correctionDescribe.observerAgeInYrs).describe.photoreceptors;
% T_receptors = cacheData.data(correctionDescribe.observerAgeInYrs).describe.T_receptors;
% [contrasts(:,iter) postreceptoralContrasts(:,iter)] = ComputeAndReportContrastsFromSpds(['Iteration ' num2str(iter, '%02.0f')] ,theCanonicalPhotoreceptors,T_receptors,...
%     backgroundSpdMeasured,modulationSpdMeasured,correctionDescribe.postreceptoralCombinations,true);

%% Make the modulation starts and stops
OLMakeModulationStartsStops(protocolParams.modulationNames,protocolParams.directionNames, protocolParams,'verbose',protocolParams.verbose);

%% Validate direction corrected primaries prior to experiemnt
OLValidateDirectionCorrectedPrimaries(ol,protocolParams,'Pre');
% OLAnalyzeValidationReceptorIsolate(validationPath, validationDescribe.postreceptoralCombinations);

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
% OLAnalyzeValidationReceptorIsolate(validationPath, validationDescribe.postreceptoralCombinations);
