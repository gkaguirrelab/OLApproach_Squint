% Make nominal stimuli for Squint experiment, for given calibration
% And run through simulated validation, to check if within tolerances

%% Get calibration, observerAge
calibration = OLGetCalibrationStructure;
observerAge = GetWithDefault('Observer age',32);

%% Melanopsin directed stimulus
MaxMelParams = OLDirectionParamsFromName('MaxMel_unipolar_275_60_667', 'alternateDictionaryFunc', 'OLDirectionParamsDictionary_Squint');
[ MaxMelDirection, MaxMelBackground ] = OLDirectionNominalFromParams(MaxMelParams, calibration, 'observerAge',observerAge);
MaxMelDirection.describe.observerAge = observerAge;
MaxMelDirection.describe.photoreceptorClasses = MaxMelDirection.describe.directionParams.photoreceptorClasses;
MaxMelDirection.describe.T_receptors = MaxMelDirection.describe.directionParams.T_receptors;
T_receptors = MaxMelDirection.describe.directionParams.T_receptors;

OLValidateDirection(MaxMelDirection, MaxMelBackground, OneLight('simulate',true,'plotWhenSimulating',false), [], 'receptors', T_receptors, 'label', 'precorrection')
figure; summarizeValidation(MaxMelDirection);

%% LMS directed stimulus
MaxLMSParams = OLDirectionParamsFromName('MaxLMS_unipolar_275_60_667', 'alternateDictionaryFunc', 'OLDirectionParamsDictionary_Squint');
[MaxLMSDirection, MaxLMSBackground ] = OLDirectionNominalFromParams(MaxLMSParams, calibration, 'observerAge',observerAge);
MaxLMSDirection.describe.observerAge = observerAge;
MaxLMSDirection.describe.photoreceptorClasses = MaxLMSDirection.describe.directionParams.photoreceptorClasses;
MaxLMSDirection.describe.T_receptors = MaxLMSDirection.describe.directionParams.T_receptors;

OLValidateDirection(MaxLMSDirection, MaxLMSBackground, OneLight('simulate',true,'plotWhenSimulating',false), [], 'receptors', T_receptors, 'label', 'precorrection')
figure; summarizeValidation(MaxLMSDirection);

%% Calculate mean chromaticities
[MelXYChromaticity] = calculateChromaticity(MaxMelDirection);
[LMSXYChromaticity] = calculateChromaticity(MaxLMSDirection);
meanXChromaticity = (MelXYChromaticity(1) + LMSXYChromaticity(1))/2;
meanYChromaticity = (MelXYChromaticity(2) + LMSXYChromaticity(2))/2;
meanBackgroundLuminance = (MaxMelDirection.describe.validation(1).luminanceActual(1) + MaxLMSDirection.describe.validation(1).luminanceActual(1))/2;

%% Lightflux: 'New' method, from params
LightFluxParams = OLDirectionParamsFromName('LightFlux_UnipolarBase', 'alternateDictionaryFunc', 'OLDirectionParamsDictionary_Squint');

LightFluxParams.desiredxy = [meanXChromaticity, meanYChromaticity];
% LightFluxParams.whichXYZ = 'xyzCIEPhys10';
% LightFluxParams.desiredMaxContrast = 4;
LightFluxParams.desiredBackgroundLuminance = meanBackgroundLuminance;

% LightFluxParams.search.primaryHeadroom = 0.000;
% LightFluxParams.search.primaryTolerance = 1e-6;
% LightFluxParams.search.checkPrimaryOutOfRange = true;
% LightFluxParams.search.lambda = 0;
LightFluxParams.search.spdToleranceFraction = 1e-1;
LightFluxParams.search.chromaticityTolerance = 0.01;
LightFluxParams.search.optimizationTarget = 'maxContrast';
% LightFluxParams.search.primaryHeadroomForInitialMax = 0.000;
% LightFluxParams.search.maxSearchIter = 3000;
 LightFluxParams.search.verbose = true;

[LightFluxDirection, LightFluxBackground] = OLDirectionNominalFromParams(LightFluxParams, calibration);
LightFluxDirection.describe.observerAge = observerAge;

LightFluxDirection.describe.directionParams.name = 'LightFlux_NewMethod';
OLValidateDirection(LightFluxDirection,LightFluxBackground,OneLight('simulate',true,'plotWhenSimulating',false),[],'receptors',T_receptors, 'label', 'precorrection');
figure; summarizeValidation(LightFluxDirection)

%{
%% Lightflux: 'Old' method
% Set up modulation primary
[modPrimary] = OLInvSolveChrom_Squint(calibration, [meanXChromaticity, meanYChromaticity]);
bgPrimary = modPrimary/5;
LightFluxDirection = OLDirection_unipolar(modPrimary-bgPrimary, calibration);
LightFluxBackground = OLDirection_unipolar(bgPrimary, calibration);

LightFluxDirection.describe.directionParams.name = 'LightFlux_OldMethod';
OLValidateDirection(LightFluxDirection,LightFluxBackground,OneLight('simulate',true,'plotWhenSimulating',false),[],'receptors',T_receptors, 'label', 'precorrection');
figure; summarizeValidation(LightFluxDirection);
%}

%{
%% 'ScaleToReceptorContrast' method
% Set up modulation primary
[modPrimary] = OLInvSolveChrom_Squint(calibration, [meanXChromaticity, meanYChromaticity]);

% Package as direction object for high-flux direction
LightFluxHigh = OLDirection_unipolar(modPrimary,calibration);

% Create low-flux direction, by scaling to specified receptor contrast
% This creates LightFluxLow, a differential direction that when added to
% LightFluxHigh will produce approximately the desired scaled contrast
[LightFluxDownscaling, scalingFactor, scaledContrast] = ScaleToReceptorContrast(LightFluxHigh,LightFluxHigh,T_receptors,[-.8 -.8 -.8 -.8]');

% Repackage as direction and background
LightFluxBackground = LightFluxHigh+LightFluxDownscaling;
LightFluxDirection = LightFluxHigh-LightFluxBackground;

LightFluxDirection.describe.directionParams.name = 'LightFlux_ScaleMethod';
OLValidateDirection(LightFluxDirection,LightFluxBackground,OneLight('simulate',true,'plotWhenSimulating',false),[],'receptors',T_receptors, 'label', 'precorrection');
figure; summarizeValidation(LightFluxDirection);
%}