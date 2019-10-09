calibration = OLGetCalibrationStructure('CalibrationType','BoxALiquidShortCableDEyePiece1_ND02','CalibrationDate','latest');


targetContrast = 12;


photoreceptorClasses = {'LConeTabulatedAbsorbance',...
    'SConeTabulatedAbsorbance',...
    'Melanopsin'};

S = calibration.describe.S;

% It also takes a parameter lambdaMaxShift: a vector with, in nm, how to
% shift each receptor lambda max from the base fundamental:

lambdaMaxShift = [-2 0 0];



% And some additional params:
fieldSize = 27.5; % degree visual angle
pupilDiameter = 6; % mm
observerAge = 28;
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
MaxMelDirection.describe.T_receptors = MaxMelDirection.describe.directionParams.T_receptors;

OLValidateDirection(MaxMelDirection, MaxMelBackground, OneLight('simulate',true,'plotWhenSimulating',false), ...
    'receptors', T_receptors, 'label', 'correctLCone')

fprintf('\n<strong>If we get the L-cone allele correct:</strong>\n');
fprintf('\tL Cone Contrast: %4.2f %%\n',  MaxMelDirection.describe.validation.contrastActual(1,1)*100);
fprintf('\tS Cone Contrast: %4.2f %%\n',  MaxMelDirection.describe.validation.contrastActual(2,1)*100);
fprintf('\tMelanopsin Contrast: %4.2f %%\n',  MaxMelDirection.describe.validation.contrastActual(3,1)*100);


%% Now look at the wrong L-cone
lambdaMaxShift = [2 0 0];

for i = 1:length(photoreceptorClasses)
    T_receptors(i,:) = GetHumanPhotoreceptorSS(S,...
        photoreceptorClasses(i),...
        fieldSize,...
        observerAge,...
        pupilDiameter,...
        lambdaMaxShift(i));
end

OLValidateDirection(MaxMelDirection, MaxMelBackground, OneLight('simulate',true,'plotWhenSimulating',false), ...
    'receptors', T_receptors, 'label', 'wrongLCone');


fprintf('\n<strong>If we get the L-cone allele wrong:</strong>\n');
fprintf('\tL Cone Contrast: %4.2f %%\n',  MaxMelDirection.describe.validation(2).contrastActual(1,1)*100);
fprintf('\tS Cone Contrast: %4.2f %%\n',  MaxMelDirection.describe.validation(2).contrastActual(2,1)*100);
fprintf('\tMelanopsin Contrast: %4.2f %%\n',  MaxMelDirection.describe.validation(2).contrastActual(3,1)*100);

