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
protocolParams.simulate.microphone = true;
protocolParams.simulate.speaker = true;
protocolParams.simulate.emg = true;
protocolParams.simulate.pupil = true;
protocolParams.simulate.udp = false;
protocolParams.simulate.observer = true;
protocolParams.simulate.operator = false;
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
protocolParams.videoRecordSystemCommandStem='ffmpeg -hide_banner -video_size 1280x720 -framerate 60.000240 -f avfoundation -i "0" -c:v mpeg4 -q:v 1';
protocolParams.audioRecordObjCommand='audiorecorder(16000,8,1,3)';

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



%% Modulations used in this experiment
%
% The set of arrays in this cell should have the same length, the entries get paired.
%
% Do not change the order of these directions without also fixing up
% the Demo and Experimental programs, which are counting on this order.
%
% The first trial type has its contrast set to 0 below, and is a blank
% trial, despite the fact that you might think it involved a modulation.
%       % Does this have to be the case? As currently constructed, the
%       first modulation below we plan to not have contrast set to 0. Do we
%       need this 0 contrast modulation for some reason?

% We want 9 different modulations: Mel, LMS, and light flux each at 3
% different contrast levels
protocolParams.modulationNames = { ...
    'MaxContrast3sPulse' ...
    'MaxContrast3sPulse' ...
    'MaxContrast3sPulse' ...
    'MaxContrast3sPulse' ...
    'MaxContrast3sPulse' ...
    'MaxContrast3sPulse' ...
    'MaxContrast3sPulse' ...
    'MaxContrast3sPulse' ...
    'MaxContrast3sPulse' ...
    };

protocolParams.directionNames = {...
    'MaxMel_275_80_667' ...
    'MaxMel_275_80_667' ...
    'MaxMel_275_80_667' ...
    'MaxLMS_275_80_667'...
    'MaxLMS_275_80_667'...
    'MaxLMS_275_80_667'...
    'LightFlux_540_380_50'...
    'LightFlux_540_380_50'...
    'LightFlux_540_380_50'...
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
    false ...
    false ...
    false ...
    ];

% Could add a validate by simulation flag here, if we ever get to a point
% where we want to trust the nominal spectra.

% Contrasts to use, relative to the powerLevel = 1 modulation in the
% directions file.
%
% Setting a contrast to 0 provides a blank trial type.

% Here are the modulations we want:
% Mel @ 400%, 200%, and 100%
% LMS @ 400%, 100%, 25%
% Light flux @ 400%, 100%, 25% -- note that we're not currently planning on
% using light flux, but it's here in the code in case we change our mind

protocolParams.trialTypeParams = [...
    struct('contrast',1) ...
    struct('contrast',0.5) ...
    struct('contrast',0.25) ...
    struct('contrast',1) ...
    struct('contrast',0.25) ...
    struct('contrast',0.0625) ...
    struct('contrast',1) ...
    struct('contrast',0.25) ...
    struct('contrast',0.0625) ...
    ];

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
     2,     3,     3,     1,     1,     2,     2,     1,     3];
 % each row here refers to a differnt deBruijn sequence governing trial
 % order within each acquisition. Each different label refers (1, 2, or 3) to a
 % different contrast level
 
 % when it comes time to actually run an acquisition below, we'll grab a
 % row from this deBruijnSequences matrix, and use that row to provide the
 % trial order for that acqusition.
    

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

% Role dependent actions - base
if any(cellfun(@(x) sum(strcmp(x,'base')),protocolParams.myRoles))
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
    
    
    
end

% Role dependent actions - oneLight
if any(cellfun(@(x) sum(strcmp(x,'oneLight')),protocolParams.myActions))

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

end

% Check the EMG output
if any(cellfun(@(x) sum(strcmp(x,'emg')),protocolParams.myActions))

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

%% Run experiment

% define our acquisition order. Because deBruijn sequences were poorly
% ordered with 2 labels, we decided to go with alternating order
acquisitionOrder = {'Mel', 'LMS', 'Mel', 'LMS', 'Mel', 'LMS', 'Mel', 'LMS'};

% set up some counters, so we know which deBruijn sequence to grab for the
% relevant acquisition
nMelAcquisitions = 1;
nLMSAcquisitions = 1;
for aa = 1:length(acquisitionOrder)
    
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
    end
    protocolParams.nTrials = length(protocolParams.trialTypeOrder);
    
    % actually launch the acquisition, and label that acquisition according
    % to where we are in the for-loop
    ApproachEngine(ol,protocolParams,'acquisitionNumber', aa,'verbose',protocolParams.verbose);
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
