protocolParams.simulate.oneLight = false;
protocolParams.simulate.radiometer = false;
protocolParams.simulate.makePlots = false;


protocolParams.boxName = 'BoxB';
protocolParams.calibrationType = 'BoxBRandomizedLongCableAEyePiece1_ND04';
protocolParams.takeCalStateMeasurements = true;
protocolParams.takeTemperatureMeasurements = false;

% Get calibration
calibration = OLGetCalibrationStructure('CalibrationType',protocolParams.calibrationType,'CalibrationDate','latest');

% Validation parameters
protocolParams.nValidationsPerDirection = 5;

commandwindow;
protocolParams.observerID = GetWithDefault('>> Enter <strong>observer name</strong>', 'HERO_xxxx');
protocolParams.observerAgeInYrs = GetWithDefault('>> Enter <strong>observer age</strong>:', 32);
protocolParams.sessionName = GetWithDefault('>> Enter <strong>session number</strong>:', 'session_1');
protocolParams.todayDate = datestr(now, 'yyyy-mm-dd');

ol = OneLight('simulate',protocolParams.simulate.oneLight,'plotWhenSimulating',protocolParams.simulate.makePlots); drawnow;

%% Let user get the radiometer set up
if ~protocolParams.simulate.radiometer
    radiometerPauseDuration = 0;
    ol.setAll(true);
    commandwindow;
    fprintf('- Focus the radiometer and press enter to pause %d seconds and start measuring.\n', radiometerPauseDuration);
    input('');
    ol.setAll(false);
    pause(radiometerPauseDuration);
    radiometer = OLOpenSpectroRadiometerObj('PR-670');
else
    radiometer = [];
end

MaxMelParams = OLDirectionParamsFromName('MaxMel_unipolar_275_60_667');
[ MaxMelDirection, MaxMelBackground ] = OLDirectionNominalFromParams(MaxMelParams, calibration, 'observerAge',protocolParams.observerAgeInYrs);

fakeMelCache = makeFakeCache(MaxMelDirection);

theCalType = 'BoxBShortLiquidLightGuideDEyePiece1_ND04';
spectroRadiometerOBJ = [];
spectroRadiometerOBJWillShutdownAfterMeasurement = false;

[cacheData spectroRadiometerOBJ] = OLCorrectCacheFileOOC_modified(...
        fakeMelCache, calibration, ...
        'igdalova@mail.med.upenn.edu', ...
        'PR-670', radiometer, spectroRadiometerOBJWillShutdownAfterMeasurement, ...
        'FullOnMeas', false, ...
        'CalStateMeas', false, ...
        'DarkMeas', false, ...
        'OBSERVER_AGE', protocolParams.observerAgeInYrs, ...
        'ReducedPowerLevels', false, ...
        'selectedCalType', theCalType, ...
        'CALCULATE_SPLATTER', false, ...
        'lambda', 0.8, ...
        'NIter', 20, ...
        'powerLevels', [0 1.0000], ...
        'doCorrection', true, ...
        'postreceptoralCombinations', [1 1 1 0 ; 1 -1 0 0 ; 0 0 1 0 ; 0 0 0 1], ...
        'outDir', fullfile('~/Desktop'), ...
        'takeTemperatureMeasurements', false);
    fprintf(' * Spectrum seeking finished!\n')
