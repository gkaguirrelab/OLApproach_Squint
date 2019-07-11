clear all

%% Get calibration, observerAge
calibration = OLGetCalibrationStructure;
observerAge = GetWithDefault('Observer age',32);

%% Melanopsin directed stimulus
% start with base melanopsin params
MaxMelParams = OLDirectionParamsFromName('MaxMel_unipolar_275_60_667', 'alternateDictionaryFunc', 'OLDirectionParamsDictionary_Squint');

% adjust to say ignore the M cone
MaxMelParams.whichReceptorsToIgnore = [2];

% aim for a higher contrast. I have plugged in here a max contrast of 0.9
% specified in bipolar contrast, which equates to 1800% contrast for
% unipolar modulations. we won't get there, but we'll aim for it.
% I will note that I'm not sure what the difference between these two
% fields are supposed to represent
MaxMelParams.baseModulationContrast = 0.9;
MaxMelParams.modulationContrast = 0.9;

% make rest of the nominal modulations
[ MaxMelDirection, MaxMelBackground ] = OLDirectionNominalFromParams(MaxMelParams, calibration, 'observerAge',observerAge, 'alternateBackgroundDictionaryFunc', 'OLBackgroundParamsDictionary_Squint');
MaxMelDirection.describe.observerAge = observerAge;
MaxMelDirection.describe.photoreceptorClasses = MaxMelDirection.describe.directionParams.photoreceptorClasses;
MaxMelDirection.describe.T_receptors = MaxMelDirection.describe.directionParams.T_receptors;
T_receptors = MaxMelDirection.describe.directionParams.T_receptors;

% validate
OLValidateDirection(MaxMelDirection, MaxMelBackground, OneLight('simulate',true,'plotWhenSimulating',false), [], 'receptors', T_receptors, 'label', 'precorrection')

% report on the validation
fprintf('L Cone Contrast: %4.2f %%\n',  MaxMelDirection.describe.validation.contrastActual(1,1)*100);
fprintf('S Cone Contrast: %4.2f %%\n',  MaxMelDirection.describe.validation.contrastActual(3,1)*100);
fprintf('Melanopsin Contrast: %4.2f %%\n',  MaxMelDirection.describe.validation.contrastActual(4,1)*100);