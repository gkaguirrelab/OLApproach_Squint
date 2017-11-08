function ApproachEngine(ol,protocolParams,varargin)
%% ApproachEngine - Run a squint protcol experiment.
%
% Usage:
%    Experiment(ol,protocolParams)
%
% Description:
%    Master program for running sequences of OneLight pulses/modulations in the acquisitionner.
%
% Input:
%    ol (object)              An open OneLight object.
%    protocolParams (struct)  The protocol parameters structure.
%
% Output:
%    None.
%
% Optional key/value pairs:
%    verbose (logical)         true       Be chatty?
%    playSound (logical)       false      Play a sound when the experiment is ready.
%    acquisitionNumber (value)        []         acquisition number for output name

%% Parse
p = inputParser;
p.addParameter('verbose',true,@islogical);
p.addParameter('playSound',false,@islogical);
p.addParameter('acquisitionNumber',[],@isnumeric);
p.parse(varargin{:});


% Establish myRole and myActions
if protocolParams.simulate.udp
    % If we are simulating the UDP connection stream, then we will operate
    % as the base and simulate the satellite component when needed.
    myRoles = {'base','satellite','satellite'};
else
    % Get local computer name
    localHostName = UDPcommunicator2.getLocalHostName();
    % Find which hostName is contained within my computer name
    idxWhichHostAmI = find(cellfun(@(x) contains(localHostName, x), protocolParams.hostNames));
    if isempty(idxWhichHostAmI)
        error(['My local host name (' localHostName ') does not match an available host name']);
    end
    % Assign me the role corresponding to my host name
    myRoles = protocolParams.hostRoles{idxWhichHostAmI};
    if ~iscell(myRoles)
        myRoles={myRoles};
    end
end

if protocolParams.simulate.udp
    % If we are simulating the UDP connection stream, then we will execute
    % all actions in this routine.
    myActions = {{'operator','observer','oneLight'}, 'pupil', 'emg'};
else
    % Get local computer name
    localHostName = UDPcommunicator2.getLocalHostName();
    % Find which hostName is contained within my computer name
    idxWhichHostAmI = find(cellfun(@(x) contains(localHostName, x), protocolParams.hostNames));
    if isempty(idxWhichHostAmI)
        error(['My local host name (' localHostName ') does not match an available host name']);
    end
    % Assign me the actions corresponding to my host name
    myActions = protocolParams.hostActions{idxWhichHostAmI};
    if ~iscell(myActions)
        myActions={myActions};
    end
end


%% Perform pre trial loop actions

% Set block to empty. If we act as the base, something will be put in here.
block = [];

% Role dependent actions - base
if any(cellfun(@(x) sum(strcmp(x,'base')),myRoles))
    %% Where the data goes
    savePath = fullfile(getpref(protocolParams.protocol, 'DataFilesBasePath'),protocolParams.observerID, protocolParams.todayDate, protocolParams.sessionName);
    if ~exist(savePath,'dir')
        mkdir(savePath);
    end
    
    %% Get acquisition number if not set
    if (isempty(p.Results.acquisitionNumber))
        protocolParams.acquisitionNumber = input('Enter acquisition number: ');
    else
        protocolParams.acquisitionNumber = p.Results.acquisitionNumber;
    end
    
    %% Start session log
    % Add protocol output name and acquisition number
    protocolParams = OLSessionLog(protocolParams,'Experiment','StartEnd','start');
    
    %% Get the modulation starts/stops for each trial type
    % Get path and filenames.  Check that someone has not
    % done something unexpected in the calling program.
    modulationDir = fullfile(getpref(protocolParams.protocol, 'ModulationStartsStopsBasePath'), protocolParams.observerID,protocolParams.todayDate,protocolParams.sessionName);
    for mm = 1:length(protocolParams.modulationNames)
        fullModulationNames = sprintf('ModulationStartsStops_%s_%s', protocolParams.modulationNames{mm}, protocolParams.directionNames{mm});
        fullModulationNames = strcat(fullModulationNames, sprintf('_trialType_%s',num2str(mm)));
        pathToModFile = [fullModulationNames '.mat'];
        modulationRead = load(fullfile(modulationDir, pathToModFile));
        modulationData(mm)= modulationRead.modulationData;
        modulation{mm} = modulationData(mm).modulation;
        frameDuration(mm) = modulationData(mm).modulationParams.timeStep;
    end
    
    %% Put together the block struct array.
    % This describes what happens on each trial of the session.
    % Once this is done we don't need the modulation data and we
    % clear that just to make sure we don't use it by accident.
    block = InitializeBlockStructArray(protocolParams,modulationData);
    clear modulationData;
    
    %% Begin the experiment
    % Play a sound to say hello.
    if (p.Results.playSound)
        t = linspace(0, 1, 10000);
        y = sin(330*2*pi*t);
        sound(y, 20000);
    end
    
    %% Set the background
    % Use the background for the first trial as the background to set.
    ol.setMirrors(block(1).modulationData.modulation.background.starts, block(1).modulationData.modulation.background.stops);
    if (p.Results.verbose), fprintf('Setting OneLight to background.\n'); end
    
    %% Adapt to background
    % Could wait here for a specified adaptation time
    
    %% Set up for responses
    if (p.Results.verbose), fprintf('\n* Creating keyboard listener\n'); end
    mglListener('init');
end



%% Run the trial loop.
tic
responseStruct = SquintTrialLoop(protocolParams,block,ol,'verbose',protocolParams.verbose);
toc



%% Execute post trial loop actions

% Role dependent actions - base
if any(cellfun(@(x) sum(strcmp(x,'base')),myRoles))
    % Turn off key listener
    mglListener('quit');
    
    % Save the experiment execution details
    % Save protocolParams, block, responseStruct.
    % Make sure not to overwrite an existing file.
    outputFile = fullfile(savePath,[protocolParams.sessionName '_' protocolParams.protocolOutputName sprintf('_acquisition%d.mat',protocolParams.acquisitionNumber)]);
    while (exist(outputFile,'file'))
        protocolParams.acquisitionNumber = input(sprintf('Output file %s exists, enter correct acquisition number: \n',outputFile));
        outputFile = fullfile(savePath,[protocolParams.sessionName sprintf('_acquisition%d.mat',protocolParams.acquisitionNumber)]);
    end
    responseStruct.acquisitionNumber = protocolParams.acquisitionNumber;
    save(outputFile,'protocolParams', 'block', 'responseStruct');
    
    % Close Session Log
    OLSessionLog(protocolParams,'Experiment','StartEnd','end');
end

% Role dependent actions - satellite
if any(cellfun(@(x) sum(strcmp(x,'satellite')),myRoles))
    % Handle the possibility that I am simulating more than one satellite
    satelliteIdx=find(cellfun(@(x) sum(strcmp(x,'satellite')),myRoles));
    for ss=1:length(satelliteIdx)

        thisAction = myActions{satelliteIdx(ss)};
        
        % Figure out where to save the data
        protocolParams = responseStruct.protocolParams;
        savePath = fullfile(getpref(protocolParams.protocol, 'DataFilesBasePath'),protocolParams.observerID, protocolParams.todayDate, protocolParams.sessionName);
        if ~exist(savePath,'dir')
            mkdir(savePath);
            warning('The base computer should have created a directory for saving data, but the satellite does not see it. Creating it so I can save.');
        end
        % Make sure not to overwrite an existing file.
        outputFile = fullfile(savePath,[protocolParams.sessionName '_' protocolParams.protocolOutputName sprintf('_acquisition%d_%s.mat',protocolParams.acquisitionNumber,thisAction)]);
        while (exist(outputFile,'file'))
            protocolParams.acquisitionNumber = input(sprintf('Output file %s exists, enter correct acquisition number: \n',outputFile));
            outputFile = fullfile(savePath,[protocolParams.sessionName sprintf('_acquisition%d_pupil.mat',protocolParams.acquisitionNumber)]);
        end
        % Save the protocol params and response struct
        responseStruct.acquisitionNumber = protocolParams.acquisitionNumber;
        save(outputFile,'protocolParams', 'responseStruct');
    end
end


end % Experiment function

