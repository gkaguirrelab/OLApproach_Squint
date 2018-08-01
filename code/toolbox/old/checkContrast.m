intendedBackgroundSPD = BoxAShortCableCEyePiece1_ND04{1}.data(60).backgroundSpd;
intendedModulationSPD = BoxAShortCableCEyePiece1_ND04{1}.data(60).modulationSpdSignedPositive;
photoreceptorClasses = BoxAShortCableCEyePiece1_ND04{1}.data(60).describe.photoreceptors;
T_receptors = BoxAShortCableCEyePiece1_ND04{1}.data(60).describe.T_receptors;
modulationSpd = intendedModulationSPD;
backgroundSpd = intendedBackgroundSPD;
[ contrasts, contrastStrings ] = calculateContrasts(backgroundSpd, modulationSpd, T_receptors, photoreceptorClasses)