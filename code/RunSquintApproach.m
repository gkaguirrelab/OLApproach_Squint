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
protocolParams.simulate.oneLight = true;
protocolParams.simulate.emg = true;
protocolParams.simulate.udp = true;
protocolParams.simulate.observer = true;
protocolParams.simulate.makePlots = true;

% define the identities of the base computer (which oversees the
% experimenta and controls the OneLight) and the satellite computer that
% handles EMG recording
protocolParams.hostNames = {'gka06', 'monkfish'};
protocolParams.hostIPs = {'128.91.12.160', '128.91.12.161'};
protocolParams.hostRoles = {'base', 'satellite'};

% Establish myRole
if protocolParams.simulate.udp
    % If we are simulating the UDP connection stream, then we will operate
    % as both the base and satellite.
    myRole = {'base', 'satellite'};
else
    % Get local computer name
    localHostName = UDPcommunicator2.getLocalHostName();
    % Find which hostName is contained within my computer name
    idxWhichHostAmI = find(cellfun(@(x) contains(localHostName, x), protocolParams.hostNames));
    if isempty(idxWhichHostAmI)
        error(['My local host name (' localHostName ') does not match an available host name']);
    end
    % Assign me the role corresponding to my host name
    myRole = protocolParams.hostRoles{idxWhichHostAmI};
end


%% Modulations used in this experiment
%
% The set of arrays in this cell should have the same length, the entries get paired.
%
% Do not change the order of these directions without also fixing up
% the Demo and Experimental programs, which are counting on this order.
%
% The first trial type has its contrast set to 0 below, and is a blank
% trial, despite the fact that you might think it involved a modulation.
protocolParams.modulationNames = { ...
    'MaxContrast3sPulse'};% ...
%    'MaxContrast3sPulse' ...
%    'MaxContrast3sPulse' ...
%    };

protocolParams.directionNames = {...
    'MaxMel_275_80_667'};%...
%    'MaxLMS_275_80_667'...
%    'LightFlux_540_380_50'...
%    };

% Flag as to whether to run the correction/validation at all for each direction.
% You set to true here entries for the unique directions, so as not
% to re-correct the same file more than once. This saves time.
%
% Note that, for obscure and boring reasons, the first entry in this cell array
% needs to be true.  That should never be a problem, because we always want to
% validate each direction once and only once, and it is as easy to validate the
% first occurrance of a direction as a subsequent one.
protocolParams.doCorrectionAndValidationFlag = {...
    true};%, ...
%    true, ...
%    true, ...
%    };

% This is also related to directions.  This determines whether the
% correction gets done using the radiometer (set to false) or just by
% simulation (set to true, just uses nominal spectra on each iteration of
% the correction.) Usually you will want all of these to be false, unless
% you've determined that for the particular box and directions you're
% working with you don't need the extra precision provided by spectrum
% correction.
protocolParams.correctBySimulation = [...
    false];% ...
%    false ...
%    false ...
%    ];

% Could add a validate by simulation flag here, if we ever get to a point
% where we want to trust the nominal spectra.

% Contrasts to use, relative to the powerLevel = 1 modulation in the
% directions file.
%
% Setting a contrast to 0 provides a blank trial type.
protocolParams.trialTypeParams = [...
    struct('contrast',1)];% ...
%    struct('contrast',1) ...
%    struct('contrast',1) ...
%    ];

%% Field size and pupil size.
%
% These are used to construct photoreceptors for validation for directions
% (e.g. light flux) where they are not available in the direction file.
% They are checked for consistency with direction parameters that specify
% these fields in OLAnalyzeDirectionCorrectedPrimaries.
protocolParams.fieldSizeDegrees = 27.5;
protocolParams.pupilDiameterMm = 8;

%% Trial timing parameters.
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
% Modulation and direction indices match on each trial, so we just specify
% them once in a single array.
protocolParams.trialTypeOrder = [1 1 1 1 1 1 1];
protocolParams.nTrials = length(protocolParams.trialTypeOrder);

%% OneLight parameters
protocolParams.boxName = 'BoxB';
protocolParams.calibrationType = 'BoxBRandomizedLongCableDStubby1_ND00';
protocolParams.takeCalStateMeasurements = true;
protocolParams.takeTemperatureMeasurements = false;

% Validation parameters
protocolParams.nValidationsPerDirection = 1;

%% Pre-experiment actions

% Set the ol variable to empty. It will be filled if we are the base.
ol = [];

% Role dependent actions - BASE
if any(strcmp('base',myRole))
    % Information we prompt for and related
    commandwindow;
    protocolParams.observerID = GetWithDefault('>> Enter <strong>observer name</strong>', 'HERO_xxxx');
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
    ol = OneLight('simulate',protocolParams.simulate.oneLight,'plotWhenSimulating',protocolParams.simulate.makePlots); drawnow;
    
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
    %
    % Could add check to OLMakeDirectionCorrectedPrimaries that pupil and field size match
    % in the direction parameters and as specified in protocol params here, if the former
    % are part of the direction. Might have to pass protocol params down into the called
    % routine. Could also do this in other routines below, I think.
    OLMakeDirectionCorrectedPrimaries(ol,protocolParams,'verbose',protocolParams.verbose);
    
    % This routine is mainly to debug the correction procedure, not particularly
    % useful once things are humming along.  One would use it if the validations
    % are coming out badly and it was necessary to track things down.
    % OLCheckPrimaryCorrection(protocolParams);
    
    %% Make the modulation starts and stops
    OLMakeModulationStartsStops(protocolParams.modulationNames,protocolParams.directionNames, protocolParams,'verbose',protocolParams.verbose);
    
    %% Validate direction corrected primaries prior to experiemnt
    OLValidateDirectionCorrectedPrimaries(ol,protocolParams,'Pre');
    OLAnalyzeDirectionCorrectedPrimaries(protocolParams,'Pre');
end

% Role dependent actions - SATELLITE
if any(strcmp('satellite',myRole))
    if protocolParams.verbose
        fprintf('Satellite is ready to launch\n')
    end
end

%% Run experiment
%
% HERE IS WHERE WE WOULD PERHAPS CREATE A LOOP OVER ACQUISITIONS, AND PASS
% THE ACQUISITION NUMBER TO THE NEXT ROUTINE
% Part of a protocol is the desired number of acquisitions.
% Calling the Experiment routine is for one acquisition.
ModulationSquint.Experiment(ol,protocolParams,'acquisitionNumber',[],'verbose',protocolParams.verbose);

%% Post-experiment actions

% Role dependent actions - BASE
if any(strcmp('base',myRole))
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

% Role dependent actions - SATELLITE
if any(strcmp('satellite',myRole))
    if protocolParams.verbose
        fprintf('The satellite is done executing the main routine\n');
    end
end

