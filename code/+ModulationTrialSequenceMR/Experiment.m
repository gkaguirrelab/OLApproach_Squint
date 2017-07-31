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

%% Get the modulation starts/stops
%
% Get path and filenames.  Check that someone has not
% done something unexpected in the calling program.
modulationDir = fullfile(getpref(protocolParams.protocol, 'ModulationStartsStopsBasePath'), protocolParams.observerID,protocolParams.todayDate,protocolParams.sessionName);
for mm = 1:length(protocolParams.modulationNames)
    fullModulationNames{mm} = sprintf('ModulationStartsStops_%s_%s', protocolParams.modulationNames{mm}, protocolParams.directionNames{mm});
    pathToModFile = [fullModulationNames{mm} '.mat'];
    modFile{mm} = load(fullfile(modulationDir, pathToModFile{mm}));
    starts{mm} = modFile{mm}.modulationData.modulation.starts;
    stops{mm} = modFile{mm}.modulationData.modulation.stops;
    frameDuration{mm} = modFile{mm}.modulationData.params.timeStep;
end

%% Put together the block struct array.
%
% This describes what happens on each trial of the session.

    function block = InitializeBlockStructArray(protocolParams,
        % Initialize
        block = struct();
        block(protocolParams.nTrials).describe = '';
        
        
        % BUILDS THE BLOCKS -- THIS SHOULD BE SEPERATED INTO A PREP SCRIPT
        for i = 1:protocolParams.nTrials
            fprintf('- Preconfiguring trial %i/%i...', i, protocolParams.nTrials);
            
            % ALL THIS SHOULD BE BE PULLED FROM EITHER DICTIONARY OR
            % MAKESTARTSSTOPS
            
            block(i).data = modulationData{Params.theDirections(i)}.modulationObj.modulation(Params.theFrequencyIndices(i), Params.thePhaseIndices(i), Params.theContrastRelMaxIndices(i));
            block(i).describe = modulationData{Params.theDirections(i)}.modulationObj.describe;
            
            % Check if the 'attentionTask' flag is set. If it is, set up the task
            % (brief stimulus offset).
            block(i).attentionTask.flag = Params.attentionTask(i);
            
            block(i).direction = block(i).data.direction;
            block(i).carrierFrequencyHz = block(i).describe.theFrequenciesHz(Params.theFrequencyIndices(i));
            
            % We pull out the background.
            block(i).data.startsBG = block(i).data.starts(:, 1);
            block(i).data.stopsBG = block(i).data.stops(:, 1);
            
            % WE NEED TO DISCUSS THE ATTENTIONAL TASK AND HOW WE WANT TO IMPLEMENT
            
            if block(i).attentionTask.flag
                nSegments = Params.trialDuration(i)/Params.attentionSegmentDuration;
                
                for s = 1:nSegments; % Iterate over the trials
                    % Define the beginning and end of the 30 second esgments
                    theStartSegmentIndex = 1/Params.timeStep*Params.attentionSegmentDuration*(s-1)+1;
                    theStopSegmentIndex = 1/Params.timeStep*Params.attentionSegmentDuration*s;
                    
                    % Flip a coin to decide whether we'll have a blank event or not
                    theCoinFlip = binornd(1, 1/3);
                    
                    % If yes, then define what the start and stop indices are for this
                    if theCoinFlip
                        theStartBlankIndex = randi([theStartSegmentIndex+Params.attentionMarginDuration*1/Params.timeStep theStopSegmentIndex-Params.attentionMarginDuration*1/Params.timeStep]);
                        theStopBlankIndex = theStartBlankIndex+Params.attentionBlankDuration*1/Params.timeStep;
                        
                        % Blank out the settings
                        block(i).data.starts(:, theStartBlankIndex:theStopBlankIndex) = 0;
                        block(i).data.stops(:, theStartBlankIndex:theStopBlankIndex) = 250;
                        
                        % Assign a Boolean vector, allowing us to keep track of
                        % when it blanked.
                        block(i).attentionTask.T(theStartBlankIndex) = 1;
                        block(i).attentionTask.T(theStopBlankIndex) = -1;
                        
                        block(i).attentionTask.segmentFlag(s) = 1;
                        block(i).attentionTask.theStartBlankIndex(s) = theStartBlankIndex;
                        block(i).attentionTask.theStopBlankIndex(s) = theStopBlankIndex;
                    else
                        % Assign a Boolean vector, allowing us to keep track of
                        % when it blanked.
                        block(i).attentionTask.T = 0;
                        block(i).attentionTask.T = 0;
                        
                        block(i).attentionTask.segmentFlag(s) = 0;
                        block(i).attentionTask.theStartBlankIndex(s) = -1;
                        block(i).attentionTask.theStopBlankIndex(s) = -1;
                    end
                    
                end
            end
            fprintf('Done\n');
        end
        
    end


%% EXPERIMENT STARTS HERE
% DO WE WANT THIS?
% Play a sound
t = linspace(0, 1, 10000);
y = sin(330*2*pi*t);
sound(y, 20000);

% Get rid of modulationData struct
clear modulationData;

% Create the OneLight object.
% This makes sure we are talking to OneLight.
ol = OneLight;

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

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%% SUBFUNCTIONS FOR PROGRAM LOGIC %%%%%%%%%%%%%%%%%%%%%%%%
%
% Contains:
%       - initParams(...)
%       - trialLoop(...)

function params = initParams(exp)
% params = initParams(exp)
% Initialize the parameters

% Much with the paths a little bit.
[~, tmp, suff] = fileparts(exp.configFileName);
exp.configFileName = fullfile(exp.configFileDir, [tmp, suff]);

% Load the config file for this condition.
cfgFile = ConfigFile(exp.configFileName);

% Convert all the ConfigFile parameters into simple struct values.
params = convertToStruct(cfgFile);
params.cacheDir = fullfile(exp.baseDir, 'cache');

% Load the calibration file.
cType = OLCalibrationTypes.(params.calibrationType);
params.oneLightCal = LoadCalFile(cType.CalFileName);

% Setup the cache.
params.obsID = exp.subject;
file_names = allwords(params.modulationFiles,',');
for i = 1:length(file_names)
    % Create the cache file name.
    params.cacheFileName{i} = file_names{i};
end

end

function params = trialLoop(params, exp)
% [params, responseStruct] = trialLoop(params, cacheData, exp)
%
% THE IS THE EXPERIMENT
% This function runs the experiment loop

%% Store out the primaries from the cacheData into a cell.  The length of
% cacheData corresponds to the number of different stimuli that are being
% shown

% Set the background to the 'idle' background appropriate for this
% trial.
fprintf('- Setting mirrors to background, waiting for t.\n');

% Initialize events variable
events = struct();
events(params.nTrials).buffer = '';

% Suppress keypresses going to the Matlab window.
ListenChar(2);

% Flush our keyboard queue.
mglGetKeyEvent;

%% Code to wait for 't' -- the go-signal from the scanner
triggerReceived = false;
while ~triggerReceived
    key = mglGetKeyEvent;
    % If a key was pressed, get the key and exit.
    if ~isempty(key)
        keyPress = key.charCode;
        if (strcmp(keyPress,'t'))
            tBlockStart = key.when;
            triggerReceived = true;
            %fprintf('  * t received.\n');
        end
    end
end

% Stop receiving t
fprintf('- Starting trials.\n');

% Iterate over trials
for trial = 1:params.nTrials
    %if params.waitForKeyPress
    %    ListenChar(0);
    %    pause;
    %end
    fprintf('* Start trial %i/%i - %s, %i Hz.\n', trial, params.nTrials, block(trial).direction, block(trial).carrierFrequencyHz);
    % Launch into OLPDFlickerSettings.
    events(trial).tTrialStart = mglGetSecs;
    % this send the flicker starts stops to the OL
    [events(trial).buffer, events(trial).t,  events(trial).counter] = ModulationTrialSequenceFlickerStartsStops(trial, params.timeStep, 1);
    events(trial).tTrialEnd = mglGetSecs;
    events(trial).attentionTask = block(trial).attentionTask;
    events(trial).describe = block(trial).describe;
    events(trial).powerLevels = block(trial).data.powerLevels;
end
tBlockEnd = mglGetSecs;

fprintf('- Done with block.\n');
ListenChar(0);

% Turn all mirrors off
%ol.setAll(false);

% Put the event information in the struct
responseStruct.events = events;
responseStruct.tBlockStart = tBlockStart;
responseStruct.tBlockEnd = tBlockEnd;

fprintf('Total duration: %f s\n', responseStruct.tBlockEnd-responseStruct.tBlockStart);

% Tack data that we want for later analysis onto params structure.  It then
% gets passed back to the calling routine and saved in our standard place.
params.responseStruct = responseStruct;

end

% Could be replaced by OLFlicker
function [keyEvents, t, counter] = ModulationTrialSequenceFlickerStartsStops(trial, frameDurationSecs, numIterations)
% OLFlicker - Flickers the OneLight.
%
% This is the function that is send the starts and stops to the OL
%
% Syntax:
% keyPress = OLFlicker(ol, stops, frameDurationSecs, numIterations)
%
% Description:
% Flickers the OneLight using the passed stops matrix until a key is
% pressed or the number of iterations is reached.
%
% Input:
% ol (OneLight) - The OneLight object.
% stops (1024xN) - The normalized [0,1] mirror stops to loop through.
% frameDurationSecs (scalar) - The duration to hold each setting until the
%     next one is loaded.
% numIterations (scalar) - The number of iterations to loop through the
%     stops.  Passing Inf causes the function to loop forever.
%
% Output:
% keyPress (char|empty) - If in continuous mode, the key the user pressed
%     to end the script.  In regular mode, this will always be empty.
%tic;
%starts = block(trial).data.starts';
%stops = block(trial).data.stops';

%keyPress = [];

% Flag whether we're checking the keyboard during the flicker loop.
%checkKB = isinf(numIterations);

% Counters to keep track of which of the stops to display and which
% iteration we're on.
iterationCount = 0;
setCount = 0;

numstops = size(block(trial).data.starts, 2);

t = zeros(1, numstops);
counter = zeros(1, numstops);
i = 0;

% This is the time of the stops change.  It gets updated everytime
% we apply new mirror stops.
mileStone = mglGetSecs + frameDurationSecs;


keyEvents = [];

while iterationCount < numIterations
    if mglGetSecs >= mileStone;
        i = i + 1;
        
        % Update the time of our next switch.
        mileStone = mileStone + frameDurationSecs;
        
        % Update our stops counter.
        setCount = mod(setCount + 1, numstops);
        
        % If we've reached the end of the stops list, iterate the
        % counter that keeps track of how many times we've gone through
        % the list.
        if setCount == 0
            iterationCount = iterationCount + 1;
            setCount = numstops;
        end
        
        % Send over the new stops.
        t(i) = mglGetSecs;
        counter(i) = setCount;
        ol.setMirrors(block(trial).data.starts(:, setCount), block(trial).data.stops(:, setCount));
    end
    
end
%toc;
keyEvents = mglListener('getAllKeyEvents');
end
end

