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
p.addParameter('acquisitionNumber',[],@isnumeric);
p.parse(varargin{:});


%% Perform pre trial loop actions

% Set block to empty. If we act as the base, something will be put in here.
stimulusStruct = [];

% Role dependent actions - base
if any(cellfun(@(x) sum(strcmp(x,'base')),protocolParams.myRoles))
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
    stimulusStruct = InitializeBlockStructArray(protocolParams,modulationData);
    clear modulationData;
        
    %% Set the background
    % Use the background for the first trial as the background to set.
    ol.setMirrors(stimulusStruct(1).modulationData.modulation.background.starts, stimulusStruct(1).modulationData.modulation.background.stops);
    if (p.Results.verbose), fprintf('Setting OneLight to background.\n'); end
    
    %% Adapt to background
    % Could wait here for a specified adaptation time
    
    %% Set up for responses
    if (p.Results.verbose), fprintf('\n* Creating keyboard listener\n'); end
    mglListener('init');
    
end

% Role dependent actions - satellite
if any(cellfun(@(x) sum(strcmp(x,'satellite')),protocolParams.myRoles))

    if ~protocolParams.simulate.pupil
        % Check that the hardware and software needed for myActions are present
        if any(cellfun(@(x) sum(strcmp(x,'pupil')),protocolParams.myActions))
            % Check that ffmpeg is installed on this computer
            if system('command -v ffmpeg')
                error('Please install ffmpeg on this computer using the command ''brew install ffmpeg''. If you need homebrew, visit https://brew.sh');
            end
        end
    end
    
    % Set up directories and file names for saving data
    
end

%% Run the trial loop.
% The protocolParams are passed as input and returned as output from
% SquintTrialLoop. This is because the satellite computers will have
% information passed to them from the base via UDP which will be added to
% the protocolParams variable.
tic
[responseStruct, protocolParams]  = SquintTrialLoop(protocolParams,stimulusStruct,ol,'verbose',protocolParams.verbose);
toc



%% Execute post trial loop actions

% Role dependent actions - base
if any(cellfun(@(x) sum(strcmp(x,'base')),protocolParams.myRoles))
    % Turn off key listener
    mglListener('quit');
    
    % Save the experiment execution details
    % Save protocolParams, block, responseStruct.
    % Make sure not to overwrite an existing file.
    outputFile = fullfile(savePath,[protocolParams.sessionName '_' protocolParams.protocolOutputName sprintf('_acquisition%02d_base.mat',protocolParams.acquisitionNumber)]);
    while (exist(outputFile,'file'))
        protocolParams.acquisitionNumber = input(sprintf('Output file %s exists, enter correct acquisition number: \n',outputFile));
        outputFile = fullfile(savePath,[protocolParams.sessionName sprintf('_acquisition%02d.mat',protocolParams.acquisitionNumber)]);
    end
    responseStruct.acquisitionNumber = protocolParams.acquisitionNumber;
    save(outputFile,'protocolParams', 'stimulusStruct', 'responseStruct');
    
    % Close Session Log
    OLSessionLog(protocolParams,'Experiment','StartEnd','end');
end

% Role dependent actions - satellite
if any(cellfun(@(x) sum(strcmp(x,'satellite')),protocolParams.myRoles))
    % Handle the possibility that I am simulating more than one satellite
    satelliteIdx=find(cellfun(@(x) sum(strcmp(x,'satellite')),protocolParams.myRoles));
    for ss=1:length(satelliteIdx)

        thisAction = protocolParams.myActions{satelliteIdx(ss)};
        
        % Figure out where to save the data
        savePath = fullfile(getpref(protocolParams.protocol, 'DataFilesBasePath'),protocolParams.observerID, protocolParams.todayDate, protocolParams.sessionName);
        if ~exist(savePath,'dir')
            mkdir(savePath);
            warning('The base computer should have created a directory for saving data, but the satellite does not see it. Creating it so I can save.');
        end
        % Make sure not to overwrite an existing file.
        outputFile = fullfile(savePath,[protocolParams.sessionName '_' protocolParams.protocolOutputName sprintf('_acquisition%02d_%s.mat',protocolParams.acquisitionNumber,thisAction)]);
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

