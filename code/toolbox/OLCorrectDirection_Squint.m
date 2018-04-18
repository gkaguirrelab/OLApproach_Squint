function OLCorrectDirection_Squint(DirectionObject, BackgroundObject, ol, radiometer)



calibration = DirectionObject.calibration;

fakeCache = makeFakeCache_Squint(DirectionObject);

[cacheData spectroRadiometerOBJ] = OLCorrectCacheFileOOC_Squint(...
        fakeCache, calibration, ol, radiometer, ...
        'igdalova@mail.med.upenn.edu', ...
        'PR-670', radiometer, false, ...
        'FullOnMeas', false, ...
        'CalStateMeas', false, ...
        'DarkMeas', false, ...
        'OBSERVER_AGE', DirectionObject.describe.observerAge, ...
        'ReducedPowerLevels', false, ...
        'CALCULATE_SPLATTER', false, ...
        'lambda', 0.8, ...
        'NIter', 20, ...
        'powerLevels', [0 1.0000], ...
        'doCorrection', true, ...
        'postreceptoralCombinations', [1 1 1 0 ; 1 -1 0 0 ; 0 0 1 0 ; 0 0 0 1], ...
        'outDir', fullfile('~/Desktop'), ...
        'takeTemperatureMeasurements', false);

    applyCorrectedCachetoDirectionObjects(cacheData, DirectionObject, BackgroundObject)
    
end