function tortureTest

[protocolParams] = getDefaultParams('calibrationType', 'BoxDLiquidShortCableDEyePiece1_ND03');

for ii = 1:1000
    sessionName = 'session_1';
    observerAgeInYrs = 32;
    observerID = ['tortureTest_boxD_', num2str(ii)];
    [ modulationData, ol, radiometer, calibration, protocolParams ] = prepExperiment(protocolParams, 'observerID', observerID, 'sessionName', sessionName, 'observerAgeInYrs', observerAgeInYrs, 'skipPause', true);
    if exist('radiometer', 'var')
    try 
        radiometer.shutDown 
    end
    close all
end
end