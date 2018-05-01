function validatePostExperiment(protocolParams, ol, radiometer)

% load up the direction objects made just prior to the experiment
savePath = fullfile(getpref('OLApproach_Squint', 'DataPath'), 'Experiments', protocolParams.approach, protocolParams.protocol, 'DirectionObjects', protocolParams.observerID, [protocolParams.todayDate, '_', protocolParams.sessionName]);


if strcmp(protocolParams.protocol, 'SquintToPulse')
    
    load(fullfile(savePath, 'MaxMelDirection.mat'), 'MaxMelDirection');
    load(fullfile(savePath, 'MaxMelBackground.mat'), 'MaxMelBackground');
end

if strcmp(protocolParams.protocol, 'SquintToPulse')
    
    load(fullfile(savePath, 'MaxLMSDirection.mat'), 'MaxLMSDirection');
    load(fullfile(savePath, 'MaxLMSBackground.mat'), 'MaxLMSBackground');
end

if strcmp(protocolParams.protocol, 'SquintToPulse') || strcmp(protocolParams.protocol, 'Screening')
    
    load(fullfile(savePath, 'LightFluxBackground.mat'), 'LightFluxBackground');
    load(fullfile(savePath, 'LightFluxDirection.mat'), 'LightFluxDirection');
end


% Let user get the radiometer set up
if ~protocolParams.simulate.radiometer
    radiometerPauseDuration = 0;
    ol.setAll(true);
    commandwindow;
    fprintf('- Focus the radiometer and press enter to pause %d seconds and start measuring.\n', radiometerPauseDuration);
    input('');
    ol.setAll(false);
    pause(radiometerPauseDuration);
end

% Validate direction corrected primaries post experiment
T_receptors = LightFluxDirection.describe.T_receptors; % the T_receptors will be the same for each direction, so just grab one
if strcmp(protocolParams.protocol, 'SquintToPulse')
    for ii = length(MaxMelDirection.describe.validation)+1:length(MaxMelDirection.describe.validation)+protocolParams.nValidationsPerDirection
        OLValidateDirection(MaxMelDirection, MaxMelBackground, ol, radiometer, 'receptors', T_receptors, 'label', 'postexperiment');
        postreceptoralContrast = ComputePostreceptoralContrastsFromLMSContrasts(MaxMelDirection.describe.validation(ii).contrastActual(1:3,1));
        MaxMelDirection.describe.validation(ii).postreceptoralContrastActual = postreceptoralContrast;
    end
end

if strcmp(protocolParams.protocol, 'SquintToPulse')
    
    for ii = length(MaxLMSDirection.describe.validation)+1:length(MaxLMSDirection.describe.validation)+protocolParams.nValidationsPerDirection
        
        OLValidateDirection(MaxLMSDirection, MaxLMSBackground, ol, radiometer, 'receptors', T_receptors, 'label', 'postexperiment');
        postreceptoralContrast = ComputePostreceptoralContrastsFromLMSContrasts(MaxLMSDirection.describe.validation(ii).contrastActual(1:3,1));
        MaxLMSDirection.describe.validation(ii).postreceptoralContrastActual = postreceptoralContrast;
    end
end

if strcmp(protocolParams.protocol, 'SquintToPulse') || strcmp(protocolParams.protocol, 'Screening')
    
    for ii = length(LightFluxDirection.describe.validation)+1:length(LightFluxDirection.describe.validation)+protocolParams.nValidationsPerDirection
        
        OLValidateDirection(LightFluxDirection, LightFluxBackground, ol, radiometer, 'receptors', T_receptors, 'label', 'postexperiment');
        postreceptoralContrast = ComputePostreceptoralContrastsFromLMSContrasts(LightFluxDirection.describe.validation(ii).contrastActual(1:3,1));
        LightFluxDirection.describe.validation(ii).postreceptoralContrastActual = postreceptoralContrast;
    end
end

%% save our directions, after validation
savePath = fullfile(getpref('OLApproach_Squint', 'DataPath'), 'Experiments', protocolParams.approach, protocolParams.protocol, 'DirectionObjects', protocolParams.observerID, [protocolParams.todayDate, '_', protocolParams.sessionName]);
if ~exist(savePath,'dir')
    mkdir(savePath);
end

if strcmp(protocolParams.protocol, 'SquintToPulse')
    
    save(fullfile(savePath, 'MaxMelDirection.mat'), 'MaxMelDirection');
    save(fullfile(savePath, 'MaxMelBackground.mat'), 'MaxMelBackground');
end

if strcmp(protocolParams.protocol, 'SquintToPulse')
    
    save(fullfile(savePath, 'MaxLMSDirection.mat'), 'MaxLMSDirection');
    save(fullfile(savePath, 'MaxLMSBackground.mat'), 'MaxLMSBackground');
end

if strcmp(protocolParams.protocol, 'SquintToPulse') || strcmp(protocolParams.protocol, 'Screening')
    
    save(fullfile(savePath, 'LightFluxBackground.mat'), 'LightFluxBackground');
    save(fullfile(savePath, 'LightFluxDirection.mat'), 'LightFluxDirection');
end

end