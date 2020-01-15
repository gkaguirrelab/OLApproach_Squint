% Make nominal stimuli for Squint experiment, for given calibration
% And run through simulated validation, to check if within tolerances.
% Operator will be prompted to select the relevant calibration and enter
% the putative observer age. The specifics of the stimuli generated within
% are meant to reflect the actual stimuli being used in the
% OLApproach_Squint experiments. One additional caveat is that the routine
% is smart enough to figure out which box we're working on based on the
% calibration name, and will choose a different set of params for the light
% flux stimulus if we're working with Box D vs. Box A. After generating the
% stimuli, we'll get a quick plot to summarize and we can check to see if
% everything looks reasonable.

% The basic use case is we have a new calibration, and let's just quickly
% check if we can generate out normal stimuli with this new calibration.

%% Get calibration, observerAge
calibration = OLGetCalibrationStructure;
observerAge = GetWithDefault('Observer age',32);

%% Melanopsin directed stimulus
MaxMelParams = OLDirectionParamsFromName('MaxMel_chrom_unipolar_275_60_4000', 'alternateDictionaryFunc', 'OLDirectionParamsDictionary_Squint');
[ MaxMelDirection, MaxMelBackground ] = OLDirectionNominalFromParams(MaxMelParams, calibration, 'observerAge',observerAge, 'alternateBackgroundDictionaryFunc', 'OLBackgroundParamsDictionary_Squint');
MaxMelDirection.describe.observerAge = observerAge;
MaxMelDirection.describe.photoreceptorClasses = MaxMelDirection.describe.directionParams.photoreceptorClasses;
MaxMelDirection.describe.T_receptors = MaxMelDirection.describe.directionParams.T_receptors;
T_receptors = MaxMelDirection.describe.directionParams.T_receptors;

OLValidateDirection(MaxMelDirection, MaxMelBackground, OneLight('simulate',true,'plotWhenSimulating',false), [], 'receptors', T_receptors, 'label', 'precorrection');
figure; MelValidation = summarizeValidation(MaxMelDirection)

%% LMS directed stimulus
MaxLMSParams = OLDirectionParamsFromName('MaxLMS_chrom_unipolar_275_60_4000', 'alternateDictionaryFunc', 'OLDirectionParamsDictionary_Squint');
[MaxLMSDirection, MaxLMSBackground ] = OLDirectionNominalFromParams(MaxLMSParams, calibration, 'observerAge',observerAge, 'alternateBackgroundDictionaryFunc', 'OLBackgroundParamsDictionary_Squint');
MaxLMSDirection.describe.observerAge = observerAge;
MaxLMSDirection.describe.photoreceptorClasses = MaxLMSDirection.describe.directionParams.photoreceptorClasses;
MaxLMSDirection.describe.T_receptors = MaxLMSDirection.describe.directionParams.T_receptors;

OLValidateDirection(MaxLMSDirection, MaxLMSBackground, OneLight('simulate',true,'plotWhenSimulating',false), [], 'receptors', T_receptors, 'label', 'precorrection');
figure; LMSValidation = summarizeValidation(MaxLMSDirection)

%% Light Flux
LightFluxParams = OLDirectionParamsFromName('LightFlux_chrom_unipolar_275_60_4000', 'alternateDictionaryFunc', 'OLDirectionParamsDictionary_Squint');
    
    % playing around with the light flux params -- these are the specific
    % parameters David played with. with the most recent calibration for BoxD
    % with the short liquid light guide and ND0.1, these gave reasonable
    % modulations
    
    whichXYZ = 'xyzCIEPhys10';
    %LightFluxParams.desiredxy = [0.60 0.38];
    %LightFluxParams.whichXYZ = whichXYZ;
%     LightFluxParams.desiredMaxContrast = 4;
%     LightFluxParams.desiredBackgroundLuminance = 221.45;
%     
%     LightFluxParams.search.primaryHeadroom = 0.000;
%     LightFluxParams.search.primaryTolerance = 1e-6;
%     LightFluxParams.search.checkPrimaryOutOfRange = true;
%     LightFluxParams.search.lambda = 0;
%     LightFluxParams.search.spdToleranceFraction = 30e-5;
%     LightFluxParams.search.chromaticityTolerance = 0.1;
%     LightFluxParams.search.optimizationTarget = 'maxContrast';
%     LightFluxParams.search.primaryHeadroomForInitialMax = 0.000;
%     LightFluxParams.search.maxSearchIter = 3000;
%     LightFluxParams.search.verbose = false;
    
    [ LightFluxDirection, LightFluxBackground ] = OLDirectionNominalFromParams(LightFluxParams, calibration, 'alternateBackgroundDictionaryFunc', 'OLBackgroundParamsDictionary_Squint', 'observerAge',observerAge);
    LightFluxDirection.describe.observerAge = observerAge;
    LightFluxDirection.describe.photoreceptorClasses = LightFluxDirection.describe.directionParams.photoreceptorClasses;
    LightFluxDirection.describe.T_receptors = LightFluxDirection.describe.directionParams.T_receptors;
OLValidateDirection(LightFluxDirection,LightFluxBackground,OneLight('simulate',true,'plotWhenSimulating',false),[],'receptors',LightFluxDirection.describe.directionParams.T_receptors, 'label', 'precorrection');
figure; LightFluxValidation = summarizeValidation(LightFluxDirection)

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