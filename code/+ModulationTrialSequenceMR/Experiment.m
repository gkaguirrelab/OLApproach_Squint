function Experiment(ol,protocolParams,varargin)
%Experiment  Run a trial sequence MR protcol experiment.
%
% Usage:
%    Experiment(ol,protocolParams)
%
% Description:
%    Master program for running sequences of OneLight pulses/modulations in the scanner.
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

%% Parse
p = inputParser;
p.addParameter('verbose',true,@islogical);
p.parse;

%% Where the data goes
savePath = fullfile(getpref(protocolParams.protocol, 'DataFilesBasePath'),protocolParams.observerID, protocolParams.todayDate, protocolParams.sessionName);
if ~exist(savePath,'dir')
    mkdir(savePath);
end
saveFileCSV = [protocolParams.observerID '-' protocolParams.protocolType '.csv'];
saveFileMAT = [protocolParams.observerID '-' protocolParams.protocolType '.mat'];

%% Get the modulation starts/stops for each trial type
%
% Get path and filenames.  Check that someone has not
% done something unexpected in the calling program.
modulationDir = fullfile(getpref(protocolParams.protocol, 'ModulationStartsStopsBasePath'), protocolParams.observerID,protocolParams.todayDate,protocolParams.sessionName);
for mm = 1:length(protocolParams.modulationNames)
    fullModulationNames = sprintf('ModulationStartsStops_%s_%s', protocolParams.modulationNames{mm}, protocolParams.directionNames{mm});
    pathToModFile = [fullModulationNames '.mat'];
    modulationRead = load(fullfile(modulationDir, pathToModFile));
    modulationData(mm)= modulationRead.modulationData;
    modulation{mm} = modulationData(mm).modulation;
    frameDuration(mm) = modulationData(mm).params.timeStep;
end

%% Put together the block struct array.
%
% This describes what happens on each trial of the session.
block = InitializeBlockStructArray(protocolParams,modulationData);

%% EXPERIMENT STARTS HERE
% DO WE WANT THIS?
% Play a sound
t = linspace(0, 1, 10000);
y = sin(330*2*pi*t);
sound(y, 20000);

%% Get rid of modulationData struct
%
% This is mainly to avoid confusion.
clear modulationData;

% Make sure our input and output pattern buffers are setup right.
%ol.InputPatternBuffer = 0;
%ol.OutputPatternBuffer = 0;

% SET THE BACKGROUND
ol.setMirrors(block(1).data.startsBG,  block(1).data.stopsBG); % Use first trial

fprintf('\n* Creating keyboard listener\n');
mglListener('init');

% Run the trial loop.
Params = trialLoop(Params, exp);

% Also save out the frequencies
Params.theFrequenciesHz = block(1).describe.theFrequenciesHz;
Params.thePhaseOffsetSec = block(1).describe.params.phaseRandSec;
Params.theContrastMax = block(1).describe.params.maxContrast;
Params.theContrastsPct = block(1).describe.theContrastRelMax;

mglListener('quit');

end

