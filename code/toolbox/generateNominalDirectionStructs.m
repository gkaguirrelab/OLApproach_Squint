function [ MaxLMSDirectionStruct, MaxMelDirectionStruct, LightFluxDirectionStruct ] = generateNominalDirectionStructs(calibrationType, observerAge)
% Function to compute nominal backgrounds and directions based on
% calibration type and subject age

% Input:
%   - calibrationType: string describing the calibration from which we want
%       to generate nominal directionStructs. The relevant calibrations for
%       Box B are:
%            'BoxBRandomizedLongCableAEyePiece1_ND04'
%            'BoxBShortLiquidLightGuideDEyePiece1_ND04'
%            'BoxBShortRandomizedCableAEyePiece1_ND04'
%   - observerAge: age of fake subject for whom we're generating these
%       nominal directionStructs
%
% Output:
%   - directionStructs (MaxLMS, MaxMel, and LightFlux): our Squint
%       experiment uses three stimulus types, and the code produces the
%       nominal directionStruct for each type. The relevant contrast
%       information is stored within as
%       directionStruct.describe.validation.predictedContrast and
%       directionStruct.describe.validation.predictedContrastPostreceptoral.
%       Note that these have the same values as the
%       actualContrast/actualContrastPostReceptoral because we're not doing
%       any direction correction or performing actual validation
%       measurements

%% Set some stuff up
% set up the calibrationStructure
protocolParams.calibrationType = calibrationType;
calibration = OLGetCalibrationStructure('CalibrationType',protocolParams.calibrationType,'CalibrationDate','latest');

% set up some information about our theoretical observer
protocolParams.observerID = '';
protocolParams.observerAgeInYrs = observerAge;

% to make these nominal directionStructs, we'll need to simulate the
% OneLight and the radiometer. Set that up here
radiometer = [];
protocolParams.simulate.oneLight = true;
protocolParams.simulate.makePlots = false;

% make the oneLight object
ol = OneLight('simulate',protocolParams.simulate.oneLight,'plotWhenSimulating',protocolParams.simulate.makePlots); drawnow;

%% Make nominal directionStructs, containing nominal primaries
% First we get the parameters for the directions from the dictionary. Then
% generate the directionStruct
MaxMelParams = OLDirectionParamsFromName('MaxMel_unipolar_275_60_667');
MaxMelDirectionStruct = OLDirectionNominalStructFromParams(MaxMelParams, calibration, 'observerAge',protocolParams.observerAgeInYrs);

MaxLMSParams = OLDirectionParamsFromName('MaxLMS_unipolar_275_60_667');
MaxLMSDirectionStruct = OLDirectionNominalStructFromParams(MaxLMSParams, calibration, 'observerAge',protocolParams.observerAgeInYrs);

LightFluxParams = OLDirectionParamsFromName('LightFlux_540_380_50');
LightFluxDirectionStruct = OLDirectionNominalStructFromParams(LightFluxParams, calibration, 'observerAge',protocolParams.observerAgeInYrs);


%% fake validate to easily determine the contrast in our nominal
% directionStructs
%
receptors = MaxLMSDirectionStruct.describe.directionParams.T_receptors;
receptorStrings = MaxLMSDirectionStruct.describe.directionParams.photoreceptorClasses;

MaxMelDirectionStruct.describe.validation = OLValidateDirection(MaxMelDirectionStruct,calibration,ol,radiometer,...
    'receptors',receptors,'receptorStrings',receptorStrings);
MaxLMSDirectionStruct.describe.validation = OLValidateDirection(MaxLMSDirectionStruct,calibration,ol,radiometer,...
    'receptors',receptors,'receptorStrings',receptorStrings);
LightFluxDirectionStruct.describe.validation = OLValidateDirection(LightFluxDirectionStruct,calibration,ol,radiometer,...
    'receptors',receptors,'receptorStrings',receptorStrings);

%% Report on these nominal contrasts
postreceptoralStrings = {'L+M+S', 'L-M', 'S-(L+M)'};
directions = {'MaxMelDirectionStruct', 'MaxLMSDirectionStruct', 'LightFluxDirectionStruct'};

% loop over directions
for dd = 1:length(directions)
    directionStruct = eval(directions{dd});
    
    fprintf('<strong>%s</strong>\n', directions{dd});
    
    % grab the relevant contrast information from the directionStruct
    receptorContrasts = directionStruct.describe.validation.predictedContrast;
    postreceptoralContrasts = directionStruct.describe.validation.predictedContrastPostReceptoral;
    
    % report of receptoral contrast
    for j = 1:size(receptors,1)
        fprintf('  * <strong>%s</strong>: contrast = %0.1f%%\n',receptorStrings{j},100*receptorContrasts(j));
    end
    
    % report on postreceptoral contrast
    NCombinations = size(postreceptoralContrasts, 1);
    fprintf('\n');
    for ii = 1:NCombinations
        fprintf('   * <strong>%s</strong>: contrast = %0.1f%%\n',postreceptoralStrings{ii},100*postreceptoralContrasts(ii));
    end
    fprintf('\n\n');
end




