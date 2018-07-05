clear all

protocolParams.simulate.oneLight = true;
protocolParams.simulate.radiometer = true;
protocolParams.simulate.makePlots = false;
protocolParams.observerAgeInYrs = 32;



% new stuff
protocolParams.backgroundDictionary = 'OLBackgroundParamsDictionary_Squint';
protocolParams.directionsDictionary = 'OLDirectionParamsDictionary_Squint';
% whichXYZ = 'xyzCIEPhys10';
% eval(['tempXYZ = load(''T_' whichXYZ ''');']);
% eval(['T_xyz = SplineCmf(tempXYZ.S_' whichXYZ ',683*tempXYZ.T_' whichXYZ ',calibration.describe.S);']);
% nativeXYZ = T_xyz*OLPrimaryToSpd(calibration,0.5*ones(size(calibration.computed.pr650M,2),1));
% nativexyY = XYZToxyY(nativeXYZ);
% nativexy = nativexyY(1:2);

% OneLight parameters
protocolParams.boxName = 'BoxA';
protocolParams.calibrationType = 'BoxALiquidLightGuideCEyePiece2ND01';
protocolParams.takeCalStateMeasurements = true;
protocolParams.takeTemperatureMeasurements = false;
calibration = OLGetCalibrationStructure('CalibrationType',protocolParams.calibrationType,'CalibrationDate','latest');


radiometer = [];

method = 'manuel';
ol = OneLight('simulate',protocolParams.simulate.oneLight,'plotWhenSimulating',protocolParams.simulate.makePlots); drawnow;



 LightFluxParams = OLDirectionParamsFromName('LightFlux_UnipolarBase', 'alternateDictionaryFunc', protocolParams.directionsDictionary);
    
    % playing around with the light flux params -- these are the specific
    % parameters David played with. with the most recent calibration for BoxD
    % with the short liquid light guide and ND0.1, these gave reasonable
    % modulations
    
    whichXYZ = 'xyzCIEPhys10';
    LightFluxParams.desiredxy = [0.51 0.40];
    LightFluxParams.whichXYZ = whichXYZ;
    LightFluxParams.desiredMaxContrast = 4;
    LightFluxParams.desiredBackgroundLuminance = 1129;
    
    LightFluxParams.search.primaryHeadroom = 0.000;
    LightFluxParams.search.primaryTolerance = 1e-6;
    LightFluxParams.search.checkPrimaryOutOfRange = true;
    LightFluxParams.search.lambda = 0;
    LightFluxParams.search.spdToleranceFraction = 30e-5;
    LightFluxParams.search.chromaticityTolerance = 0.001;
    LightFluxParams.search.optimizationTarget = 'maxContrast';
    LightFluxParams.search.primaryHeadroomForInitialMax = 0.000;
    LightFluxParams.search.maxSearchIter = 3000;
    LightFluxParams.search.verbose = false;
    
    [ LightFluxDirection, LightFluxBackground ] = OLDirectionNominalFromParams(LightFluxParams, calibration);
    LightFluxDirection.describe.observerAge = protocolParams.observerAgeInYrs;


    [modPrimary] = OLInvSolveChrom_Squint(calibration, [0.51 0.40]);
    modPrimary = modPrimary * 1.5;
    bgPrimary = modPrimary/5;
    LightFluxDirection.differentialPrimaryValues = modPrimary - bgPrimary;
    LightFluxDirection.SPDdifferentialDesired = OLPrimaryToSpd(calibration, (modPrimary - bgPrimary), 'differentialMode', true);
    LightFluxBackground.differentialPrimaryValues = bgPrimary;
    LightFluxBackground.SPDdifferentialDesired = OLPrimaryToSpd(calibration, bgPrimary, 'differentialMode', true);
    LightFluxDirection.describe.background.differentialPrimaryValues = bgPrimary;
    LightFluxDirection.describe.background.SPDdifferentialDesired = OLPrimaryToSpd(calibration, bgPrimary, 'differentialMode', true);


MaxMelParams = OLDirectionParamsFromName('MaxMel_unipolar_275_60_667');
[ MaxMelDirection, MaxMelBackground ] = OLDirectionNominalFromParams(MaxMelParams, calibration, 'observerAge',protocolParams.observerAgeInYrs);
T_receptors = MaxMelDirection.describe.directionParams.T_receptors; % the T_receptors will be the same for each direction, so just grab one
 LightFluxDirection.describe.photoreceptorClasses = MaxMelDirection.describe.directionParams.photoreceptorClasses;
    LightFluxDirection.describe.T_receptors = MaxMelDirection.describe.directionParams.T_receptors;


OLValidateDirection(LightFluxDirection, LightFluxBackground, ol, radiometer, 'receptors', T_receptors, 'label', 'precorrection')

summarizeValidation(LightFluxDirection);

% verify chromaticity of background:
load T_xyz1931
S = [380 2 201];
backgroundSpd = LightFluxDirection.describe.validation(1).SPDbackground.measuredSPD;
T_xyz = SplineCmf(S_xyz1931,683*T_xyz1931,S);
chromaticityXY = T_xyz(1:2,:)*backgroundSpd/sum(T_xyz*backgroundSpd)