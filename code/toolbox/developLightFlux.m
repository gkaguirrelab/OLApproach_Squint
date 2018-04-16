protocolParams.simulate.oneLight = true;
protocolParams.simulate.radiometer = true;
protocolParams.simulate.makePlots = false;
protocolParams.observerAgeInYrs = 32;



% new stuff
backgroundAlternateDictionary = 'OLBackgroundParamsDictionary_Squint';
directionAlternateDictionary = 'OLDirectionParamsDictionary_Squint';
% whichXYZ = 'xyzCIEPhys10';
% eval(['tempXYZ = load(''T_' whichXYZ ''');']);
% eval(['T_xyz = SplineCmf(tempXYZ.S_' whichXYZ ',683*tempXYZ.T_' whichXYZ ',calibration.describe.S);']);
% nativeXYZ = T_xyz*OLPrimaryToSpd(calibration,0.5*ones(size(calibration.computed.pr650M,2),1));
% nativexyY = XYZToxyY(nativeXYZ);
% nativexy = nativexyY(1:2);

% OneLight parameters
protocolParams.boxName = 'BoxB';
protocolParams.calibrationType = 'BoxBShortLiquidLightGuideDEyePiece1_ND04';
protocolParams.takeCalStateMeasurements = true;
protocolParams.takeTemperatureMeasurements = false;
calibration = OLGetCalibrationStructure('CalibrationType',protocolParams.calibrationType,'CalibrationDate','latest');


radiometer = [];
ol = OneLight('simulate',protocolParams.simulate.oneLight,'plotWhenSimulating',protocolParams.simulate.makePlots); drawnow;

LightFluxParams = OLDirectionParamsFromName('LightFlux_UnipolarBase', 'alternateDictionaryFunc', directionAlternateDictionary);
LightFluxParams.backgroundParams = OLBackgroundParamsFromName(LightFluxParams.backgroundName, 'alternateDictionaryFunc', backgroundAlternateDictionary);

[LightFluxDirection, LightFluxBackground ] = OLDirectionNominalFromParams(LightFluxParams, calibration);


MaxMelParams = OLDirectionParamsFromName('MaxMel_unipolar_275_60_667');
[ MaxMelDirection, MaxMelBackground ] = OLDirectionNominalFromParams(MaxMelParams, calibration, 'observerAge',protocolParams.observerAgeInYrs);
T_receptors = MaxMelDirection.describe.directionParams.T_receptors; % the T_receptors will be the same for each direction, so just grab one


OLValidateDirection(LightFluxDirection, LightFluxBackground, ol, radiometer, 'receptors', T_receptors, 'label', 'precorrection')

summarizeValidation(LightFluxDirection);

% verify chromaticity of background:
load T_xyz1931
S = [380 2 201];
backgroundSpd = LightFluxDirection.describe.validation(1).SPDbackground.measuredSPD;
T_xyz = SplineCmf(S_xyz1931,683*T_xyz1931,S);
chromaticityXY = T_xyz(1:2,:)*backgroundSpd/sum(T_xyz*backgroundSpd)