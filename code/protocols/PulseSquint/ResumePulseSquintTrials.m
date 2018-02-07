function ResumePulseSquintTrials(protocolParams)

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

%% Pre-experiment actions

% Set the ol variable to empty. It will be filled if we are the base.
ol = [];

% Role dependent actions - base
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
    
    % use session number to get some information about which log we're
    % writing to
    protocolParams.sessionLogOutDir = fullfile(getpref(protocolParams.protocol,'SessionRecordsBasePath'),protocolParams.observerID,protocolParams.todayDate,protocolParams.sessionName);
    fileName = [protocolParams.observerID '_' protocolParams.sessionName '.log'];
    protocolParams.fullFileName = fullfile(protocolParams.sessionLogOutDir,fileName);
    
    startingAcquisitionNumber = protocolParams.acquisitionNumber;
    
    
    
    % make sure we're resuming what we think we're resuming, specifically
    % that the relevant session already exists
    sessionDir = fullfile(getpref(protocolParams.protocol,'SessionRecordsBasePath'),protocolParams.observerID,protocolParams.todayDate, protocolParams.sessionName);
    if exist(sessionDir,'dir')
        fprintf('Found the relevant session folder.\n')
    else
        error('Could not find the relevant session folder')
    end
    
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
    ol.setAll(false);
    
    
end


%% make sure the satellites have all of the information they need
% they really just need which acquisition we're starting with, the other
% stuff will be provided by the base
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


%% Pause dropBox syncing
dropBoxSyncingStatus = pauseUnpauseDropbox('command', '--pause');
if protocolParams.verbose
    fprintf('DropBox syncing status set to %d\n',dropBoxSyncingStatus);
end

%% Run experiment

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
