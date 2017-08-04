%Simulation 

generatePlots   = true;
trialTime       = 12000;
contrastSupport = logspace(0,2,7);
frequency       = 2.0;
stimResponseVec = boyntonCRF(contrastSupport, frequency);

[ fitParamsMean, fitParamsSD ] = t_IAMPDesignFMRIExperiment('generatePlots' ...
                                 ,generatePlots, 'trialTime', trialTime,...
                                 'stimResponseVec',stimResponseVec');