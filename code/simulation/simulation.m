%Simulation 

generatePlots   = true;
trialTime       = 12000;
contrastSupport = [0 20 40 60 80 100];
frequency       = 0.5;
stimResponseVec = boyntonCRF(contrastSupport, frequency);

[ fitParamsMean, fitParamsSD ] = t_IAMPDesignFMRIExperiment('generatePlots' ...
                                 ,generatePlots, 'trialTime', trialTime,...
                                 'stimResponseVec',stimResponseVec');