clear all

%% Get calibration, observerAge
calibration = OLGetCalibrationStructure;
observerAge = GetWithDefault('Observer age',32);
protocolParams.whichLCone = GetWithDefault('>> Enter which L cone variant:', 'left/right');


targetContrast = 12;

% Extract wavelength sampling
S = calibration.describe.S;

%% Create receptor fundamentals
% Receptor fundamentals are produced by SST/GetHumanPhotoreceptorSS. First
% pass in which base receptor fundamentals to use, as strings specifying
% the photoreceptor classes. In this case, we want to specify two L cones,
% no M cone, an S cone, and melanopsin.
photoreceptorClasses = {'LConeTabulatedAbsorbance',...
    'SConeTabulatedAbsorbance',...
    'Melanopsin'};

% It also takes a parameter lambdaMaxShift: a vector with, in nm, how to
% shift each receptor lambda max from the base fundamental:

if strcmp(protocolParams.whichLCone, 'left')
    lambdaMaxShift = [-2 0 0];
elseif strcmp(protocolParams.whichLCone, 'right')
    lambdaMaxShift = [2 0 0];
else strcmp(protocolParams.whichLCone, 'default')
    lambdaMaxShift = [0 0 0];
end


% And some additional params:
fieldSize = 27.5; % degree visual angle
pupilDiameter = 6; % mm
%observerAge = 32;
headroom = 0;

% GetHumanPhotoreceptorSS is being a pain, and won't create the whole set
% correctly. We'll create them one  at a time to circumvent this:
for i = 1:length(photoreceptorClasses)
    T_receptors(i,:) = GetHumanPhotoreceptorSS(S,...
        photoreceptorClasses(i),...
        fieldSize,...
        observerAge,...
        pupilDiameter,...
        lambdaMaxShift(i));
end


%% Create melanopsin stimuli
% Convert to logical


% Convert to indices that SST expects
whichReceptorsToIsolate = {[3]};
whichReceptorsToIgnore = {[]};
whichReceptorsToMinimize = {[]};


% Create optimized background
% Get empty background params object
backgroundParams = OLBackgroundParams_Optimized;

% Fill in params
backgroundParams.backgroundObserverAge = observerAge;
backgroundParams.pupilDiameterMm = pupilDiameter;
backgroundParams.fieldSizeDegrees = fieldSize;
backgroundParams.photoreceptorClasses = photoreceptorClasses;
backgroundParams.T_receptors = T_receptors;

% Define isolation params
backgroundParams.whichReceptorsToIgnore = whichReceptorsToIgnore;
backgroundParams.whichReceptorsToIsolate = whichReceptorsToIsolate;
backgroundParams.whichReceptorsToMinimize = whichReceptorsToMinimize;
backgroundParams.modulationContrast = OLUnipolarToBipolarContrast(targetContrast);
backgroundParams.primaryHeadRoom = headroom;

% Make background
background = OLBackgroundNominalFromParams(backgroundParams, calibration);

% Set unipolar direction params
% Get empty direction params object
directionParams = OLDirectionParams_Unipolar;

% Fill in params
directionParams.pupilDiameterMm = pupilDiameter;
directionParams.fieldSizeDegrees = fieldSize;
directionParams.photoreceptorClasses = photoreceptorClasses;
directionParams.T_receptors = T_receptors;

% Define isolation params
directionParams.whichReceptorsToIgnore = [whichReceptorsToIgnore{:}];
directionParams.whichReceptorsToIsolate = [whichReceptorsToIsolate{:}];
directionParams.whichReceptorsToMinimize = [whichReceptorsToMinimize{:}];
directionParams.modulationContrast = OLUnipolarToBipolarContrast(targetContrast);
directionParams.primaryHeadRoom = headroom;

% Set background
directionParams.background = background;

% Make direction, unipolar background
[MaxMelDirection, MaxMelBackground] = OLDirectionNominalFromParams(directionParams, calibration);
fprintf('Contrasts for melanopsin-directed stimuli:\n');
MaxMelDirection.ToDesiredReceptorContrast(MaxMelBackground, T_receptors)

%% Create L-S stimuli
% Convert to logical
% Convert to indices that SST expects
whichReceptorsToIsolate = {[1 2]};
whichReceptorsToIgnore = {[]};
whichReceptorsToMinimize = {[]};


% Create optimized background
% Get empty background params object
backgroundParams = OLBackgroundParams_Optimized;

% Fill in params
backgroundParams.backgroundObserverAge = observerAge;
backgroundParams.pupilDiameterMm = pupilDiameter;
backgroundParams.fieldSizeDegrees = fieldSize;
backgroundParams.photoreceptorClasses = photoreceptorClasses;
backgroundParams.T_receptors = T_receptors;

% Define isolation params
backgroundParams.whichReceptorsToIgnore = whichReceptorsToIgnore;
backgroundParams.whichReceptorsToIsolate = whichReceptorsToIsolate;
backgroundParams.whichReceptorsToMinimize = whichReceptorsToMinimize;
backgroundParams.modulationContrast = {repmat(OLUnipolarToBipolarContrast(targetContrast), 1, length(whichReceptorsToIsolate{:}))};
backgroundParams.primaryHeadRoom = headroom;

% Make background
background = OLBackgroundNominalFromParams(backgroundParams, calibration);

% Set unipolar direction params
% Get empty direction params object
directionParams = OLDirectionParams_Unipolar;

% Fill in params
directionParams.pupilDiameterMm = pupilDiameter;
directionParams.fieldSizeDegrees = fieldSize;
directionParams.photoreceptorClasses = photoreceptorClasses;
directionParams.T_receptors = T_receptors;

% Define isolation params
directionParams.whichReceptorsToIgnore = [whichReceptorsToIgnore{:}];
directionParams.whichReceptorsToIsolate = [whichReceptorsToIsolate{:}];
directionParams.whichReceptorsToMinimize = [whichReceptorsToMinimize{:}];
directionParams.modulationContrast = [repmat(OLUnipolarToBipolarContrast(targetContrast), 1, length(whichReceptorsToIsolate{:}))];
directionParams.primaryHeadRoom = headroom;

% Set background
directionParams.background = background;

% Make direction, unipolar background
[MaxLMSDirection, MaxLMSBackground] = OLDirectionNominalFromParams(directionParams, calibration);
fprintf('Contrasts for cone-directed stimuli:\n')

MaxLMSDirection.ToDesiredReceptorContrast(MaxLMSBackground, T_receptors)

