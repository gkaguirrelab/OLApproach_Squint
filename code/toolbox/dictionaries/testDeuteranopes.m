clear all

%% Get calibration, observerAge
calibration = OLGetCalibrationStructure;
observerAge = GetWithDefault('Observer age',32);

%% Melanopsin directed stimulus
% start with base melanopsin params
MaxMelParams = OLDirectionParamsFromName('MaxMel_unipolar_275_60_667', 'alternateDictionaryFunc', 'OLDirectionParamsDictionary_Squint');

% adjust to say ignore the M cone
% for the direction
MaxMelParams.whichReceptorsToIgnore = [2];
% for the background. accomplish this by using special background that's
% already defined to have M cone ignored
MaxMelParams.backgroundName = 'MelanopsinDirectedForDeuteranopes_275_60_667';

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
fprintf('\n<strong>For melanopsin stimuli:</strong>\n');
fprintf('\tL Cone Contrast: %4.2f %%\n',  MaxMelDirection.describe.validation.contrastActual(1,1)*100);
fprintf('\tS Cone Contrast: %4.2f %%\n',  MaxMelDirection.describe.validation.contrastActual(3,1)*100);
fprintf('\tMelanopsin Contrast: %4.2f %%\n',  MaxMelDirection.describe.validation.contrastActual(4,1)*100);

%% LMS directed stimulus
% start with base LMS prams
MaxLMSParams = OLDirectionParamsFromName('MaxLMS_unipolar_275_60_667', 'alternateDictionaryFunc', 'OLDirectionParamsDictionary_Squint');

% aim for a higher contrast. I have plugged in here a max contrast of 0.9
% specified in bipolar contrast, which equates to 1800% contrast for
% unipolar modulations. we won't get there, but we'll aim for it.
% I will note that I'm not sure what the difference between these two
% fields are supposed to represent
MaxLMSParams.baseModulationContrast = 0.9;
MaxLMSParams.modulationContrast = 0.9;

% adjust to say ignore the M cone
% for the direction
MaxLMSParams.modulationContrast = [MaxLMSParams.baseModulationContrast MaxLMSParams.baseModulationContrast];
MaxLMSParams.whichReceptorsToIsolate = [1 3];
MaxLMSParams.whichReceptorsToIgnore = [2];
% for the background
MaxLMSParams.backgroundName = 'LMSDirectedForDeuteranopes_275_60_667';

[MaxLMSDirection, MaxLMSBackground ] = OLDirectionNominalFromParams(MaxLMSParams, calibration, 'observerAge',observerAge, 'alternateBackgroundDictionaryFunc', 'OLBackgroundParamsDictionary_Squint');
MaxLMSDirection.describe.observerAge = observerAge;
MaxLMSDirection.describe.photoreceptorClasses = MaxLMSDirection.describe.directionParams.photoreceptorClasses;
MaxLMSDirection.describe.T_receptors = MaxLMSDirection.describe.directionParams.T_receptors;

OLValidateDirection(MaxLMSDirection, MaxLMSBackground, OneLight('simulate',true,'plotWhenSimulating',false), [], 'receptors', T_receptors, 'label', 'precorrection')

% report on the validation
fprintf('\n<strong>For LMS stimuli:</strong>\n');
fprintf('\tL Cone Contrast: %4.2f %%\n',  MaxLMSDirection.describe.validation.contrastActual(1,1)*100);
fprintf('\tS Cone Contrast: %4.2f %%\n',  MaxLMSDirection.describe.validation.contrastActual(3,1)*100);
fprintf('\tMelanopsin Contrast: %4.2f %%\n',  MaxLMSDirection.describe.validation.contrastActual(4,1)*100);

%% LightFlux directed stimulus
% start with base LMS prams
LightFluxParams = OLDirectionParamsFromName('MaxLMS_unipolar_275_60_667', 'alternateDictionaryFunc', 'OLDirectionParamsDictionary_Squint');

% aim for a higher contrast. I have plugged in here a max contrast of 0.9
% specified in bipolar contrast, which equates to 1800% contrast for
% unipolar modulations. we won't get there, but we'll aim for it.
% I will note that I'm not sure what the difference between these two
% fields are supposed to represent
LightFluxParams.baseModulationContrast = 0.9999;
LightFluxParams.modulationContrast = 0.9999;

% adjust to say ignore the M cone
% for the direction
LightFluxParams.modulationContrast = [LightFluxParams.baseModulationContrast LightFluxParams.baseModulationContrast LightFluxParams.baseModulationContrast];
LightFluxParams.whichReceptorsToIsolate = [1 3 4];
LightFluxParams.whichReceptorsToIgnore = [2];
% for the background
LightFluxParams.backgroundName = 'LightFluxForDeuteranopes_275_60_667';

[LightFluxDirection, LightFluxBackground ] = OLDirectionNominalFromParams(LightFluxParams, calibration, 'observerAge',observerAge, 'alternateBackgroundDictionaryFunc', 'OLBackgroundParamsDictionary_Squint');
LightFluxDirection.describe.observerAge = observerAge;
LightFluxDirection.describe.photoreceptorClasses = LightFluxDirection.describe.directionParams.photoreceptorClasses;
LightFluxDirection.describe.T_receptors = LightFluxDirection.describe.directionParams.T_receptors;

OLValidateDirection(LightFluxDirection, LightFluxBackground, OneLight('simulate',true,'plotWhenSimulating',false), [], 'receptors', T_receptors, 'label', 'precorrection')

% report on the validation
fprintf('\n<strong>For LightFlux stimuli:</strong>\n');
fprintf('\tL Cone Contrast: %4.2f %%\n',  LightFluxDirection.describe.validation.contrastActual(1,1)*100);
fprintf('\tS Cone Contrast: %4.2f %%\n',  LightFluxDirection.describe.validation.contrastActual(3,1)*100);
fprintf('\tMelanopsin Contrast: %4.2f %%\n',  LightFluxDirection.describe.validation.contrastActual(4,1)*100);