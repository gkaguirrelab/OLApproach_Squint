function tortureTest

[protocolParams] = getDefaultParams('calibrationType', 'BoxALiquidLightGuideCEyePiece2ND01');

for ii = 7:1000
    sessionName = 'session_1';
    observerAgeInYrs = 32;
    observerID = ['tortureTest_', num2str(ii)];
    [ modulationData, ol, radiometer, calibration, protocolParams ] = prepExperiment(protocolParams, 'observerID', observerID, 'sessionName', sessionName, 'observerAgeInYrs', observerAgeInYrs, 'skipPause', true);
    if exist('radiometer', 'var')
    try 
        radiometer.shutDown 
    end
    close all
end
end