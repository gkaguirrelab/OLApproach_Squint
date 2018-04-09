protocolParams.simulate.oneLight = true;
protocolParams.simulate.radiometer = true;

protocolParams.observerAgeInYrs = 32;

% OneLight parameters
protocolParams.boxName = 'BoxB';
protocolParams.calibrationType = 'BoxBShortLiquidLightGuideDEyePiece1_ND04';
protocolParams.takeCalStateMeasurements = true;
protocolParams.takeTemperatureMeasurements = false;

        radiometer = [];


% Get calibration
calibration = OLGetCalibrationStructure('CalibrationType',protocolParams.calibrationType,'CalibrationDate','latest');

LightFluxParams = OLDirectionParamsFromName('LightFlux_540_380_50');
%LightFluxParams.backgroundName = 'LightFlux_590_390_50';
%LightFluxParams.lightFluxDesiredXY(1) = .590;
%LightFluxParams.lightFluxDesiredXY(2) = .390;

[LightFluxDirection, LightFluxBackground ] = OLDirectionNominalFromParams(LightFluxParams, calibration);


MaxMelParams = OLDirectionParamsFromName('MaxMel_unipolar_275_60_667');
[ MaxMelDirection, MaxMelBackground ] = OLDirectionNominalFromParams(MaxMelParams, calibration, 'observerAge',protocolParams.observerAgeInYrs);
    T_receptors = MaxMelDirection.describe.directionParams.T_receptors; % the T_receptors will be the same for each direction, so just grab one


OLValidateDirection(LightFluxDirection, LightFluxBackground, ol, radiometer, 'receptors', LightFluxDirection.describe.directionParams.T_receptors, 'label', 'precorrection')

summarizeValidation(LightFluxDirection);

% verify chromaticity of background:
load T_xyz1931
S = [380 2 201];
backgroundSpd = LightFluxDirection.describe.validation(1).SPDbackground.measuredSPD
T_xyz = SplineCmf(S_xyz1931,683*T_xyz1931,S);
chromaticityXY = T_xyz(1:2,:)*backgroundSpd/sum(T_xyz*backgroundSpd)