function tortureTest

[protocolParams] = getDefaultParams;

for ii = 1:1000
    sessionName = 'session_1';
    observerAgeInYrs = 32;
    observerID = ['tortureTest_', num2str(ii)];
    [ modulationData ] = prepExperiment(protocolParams, 'observerID', observerID, 'sessionName', sessionName, 'observerAgeInYrs', observerAgeInYrs, 'skipPause', true);
end