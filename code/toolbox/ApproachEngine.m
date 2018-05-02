function ApproachEngine(ol,protocolParams, trialList, UDPobj, varargin)
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
%    trialList                Struct array defining each trial
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

% Role dependent actions - base
if any(cellfun(@(x) sum(strcmp(x,'base')),protocolParams.myRoles))
    %% Where the data goes
    
    
    savePath = fullfile(getpref(protocolParams.protocol, 'DataFilesBasePath'),protocolParams.observerID, [protocolParams.todayDate, '_',  protocolParams.sessionName]);
    
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
      
    %% Set the background
    % Use the background for the first trial as the background to set.
    ol.setMirrors(trialList(1).modulationData.modulation.background.starts, trialList(1).modulationData.modulation.background.stops);
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
[responseStruct, protocolParams]  = SquintTrialLoop(protocolParams,trialList,ol, UDPobj,'verbose',protocolParams.verbose);
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
    save(outputFile,'protocolParams', 'trialList', 'responseStruct');
    
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
        
        savePath = fullfile(getpref(protocolParams.protocol, 'DataFilesBasePath'),protocolParams.observerID, [protocolParams.todayDate, '_', protocolParams.sessionName]);
        
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

