function validatePostExperiment(protocolParams, ol, radiometer)
% Perform validation measurments upon the completion of the experiment.
%
% Syntax:
%  validatePostExperiment(protocolParams, ol, radiometer)

% Description:
%   This function takes measurements of the relevant direction objects used
%   as part of an OLApproach_Squint experiment, performs a number of
%   validation measurements, and appends these validation measurements to
%   the directionObject.describe.validation sub-subfield.

% Inputs:
%   protocolParams        - A struct that defines the specifics of the
%                           experiment. A key subfield for this function is
%                           the nValidationsPerDirection (how many
%                           measurements to take for each directionObject;
%                           normally 5 for this experiment).
%  ol                     - The instantiated OneLight object
%  radiometer             - The instantiated radiometer object

% load up the direction objects made just prior to the experiment
savePath = fullfile(getpref('OLApproach_Squint', 'DataPath'), 'Experiments', protocolParams.approach, protocolParams.protocol, 'DirectionObjects', protocolParams.observerID, [protocolParams.todayDate, '_', protocolParams.sessionName]);


if strcmp(protocolParams.protocol, 'SquintToPulse') || strcmp(protocolParams.protocol, 'Deuteranopes')
    
    load(fullfile(savePath, 'MaxMelDirection.mat'), 'MaxMelDirection');
    load(fullfile(savePath, 'MaxMelBackground.mat'), 'MaxMelBackground');
end

if strcmp(protocolParams.protocol, 'SquintToPulse') || strcmp(protocolParams.protocol, 'Deuteranopes')
    
    load(fullfile(savePath, 'MaxLMSDirection.mat'), 'MaxLMSDirection');
    load(fullfile(savePath, 'MaxLMSBackground.mat'), 'MaxLMSBackground');
end

if strcmp(protocolParams.protocol, 'SquintToPulse') || strcmp(protocolParams.protocol, 'Screening') || strcmp(protocolParams.protocol, 'Deuteranopes')
    
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

takeTemperatureMeasurements = true;
measureStateTrackingSPDs = true;
[takeTemperatureMeasurements, quitNow, theLJdev] = OLCalibrator.OpenLabJackTemperatureProbe(takeTemperatureMeasurements);
    if (quitNow)
        return;
    end

% Validate direction corrected primaries post experiment
T_receptors = LightFluxDirection.describe.T_receptors; % the T_receptors will be the same for each direction, so just grab one
if strcmp(protocolParams.protocol, 'SquintToPulse')
    for ii = length(MaxMelDirection.describe.validation)+1:length(MaxMelDirection.describe.validation)+protocolParams.nValidationsPerDirection
        OLValidateDirection(MaxMelDirection, MaxMelBackground, ol, radiometer, 'receptors', T_receptors, 'label', 'postexperiment', 'temperatureProbe', theLJdev, ...
            'measureStateTrackingSPDs', measureStateTrackingSPDs);
        postreceptoralContrast = ComputePostreceptoralContrastsFromLMSContrasts(MaxMelDirection.describe.validation(ii).contrastActual(1:3,1));
        MaxMelDirection.describe.validation(ii).postreceptoralContrastActual = postreceptoralContrast;
    end
end

if strcmp(protocolParams.protocol, 'SquintToPulse')
    
    for ii = length(MaxLMSDirection.describe.validation)+1:length(MaxLMSDirection.describe.validation)+protocolParams.nValidationsPerDirection
        
        OLValidateDirection(MaxLMSDirection, MaxLMSBackground, ol, radiometer, 'receptors', T_receptors, 'label', 'postexperiment', 'temperatureProbe', theLJdev, ...
            'measureStateTrackingSPDs', measureStateTrackingSPDs);
        postreceptoralContrast = ComputePostreceptoralContrastsFromLMSContrasts(MaxLMSDirection.describe.validation(ii).contrastActual(1:3,1));
        MaxLMSDirection.describe.validation(ii).postreceptoralContrastActual = postreceptoralContrast;
    end
end

if strcmp(protocolParams.protocol, 'SquintToPulse') || strcmp(protocolParams.protocol, 'Screening')
    
    for ii = length(LightFluxDirection.describe.validation)+1:length(LightFluxDirection.describe.validation)+protocolParams.nValidationsPerDirection
        
        OLValidateDirection(LightFluxDirection, LightFluxBackground, ol, radiometer, 'receptors', T_receptors, 'label', 'postexperiment', 'temperatureProbe', theLJdev, ...
            'measureStateTrackingSPDs', measureStateTrackingSPDs);
        postreceptoralContrast = ComputePostreceptoralContrastsFromLMSContrasts(LightFluxDirection.describe.validation(ii).contrastActual(1:3,1));
        LightFluxDirection.describe.validation(ii).postreceptoralContrastActual = postreceptoralContrast;
    end
end

%% tell the console what the background luminance of the light flux stimuli was
LightFluxPostValidationJustPost = summarizeValidation(LightFluxDirection, 'whichValidationPrefix', 'postexperiment', 'plot', 'off');
lightFluxBackgroundLuminance = median(LightFluxPostValidationJustPost.backgroundLuminance);

if lightFluxBackgroundLuminance > 254.6685
    backgroundLuminance = 0;
    fprintf('<strong>Background luminance for lightflux stimuli is %.2f, which is too bright</strong>\n', lightFluxBackgroundLuminance);
elseif lightFluxBackgroundLuminance < 160.685
    backgroundLuminance = 0;
    fprintf('<strong>Background luminance for lightflux stimuli is %.2f, which is too dim</strong>\n', lightFluxBackgroundLuminance);
else
    backgroundLuminance = 1;
    fprintf('Background luminance for lightflux stimuli is %.2f\n', lightFluxBackgroundLuminance);
end


%% save our directions, after validation
savePath = fullfile(getpref('OLApproach_Squint', 'DataPath'), 'Experiments', protocolParams.approach, protocolParams.protocol, 'DirectionObjects', protocolParams.observerID, [protocolParams.todayDate, '_', protocolParams.sessionName]);
if ~exist(savePath,'dir')
    mkdir(savePath);
end

if strcmp(protocolParams.protocol, 'SquintToPulse') || strcmp(protocolParams.protocol, 'Deuteranopes')
    
    save(fullfile(savePath, 'MaxMelDirection.mat'), 'MaxMelDirection');
    save(fullfile(savePath, 'MaxMelBackground.mat'), 'MaxMelBackground');
end

if strcmp(protocolParams.protocol, 'SquintToPulse') || strcmp(protocolParams.protocol, 'Deuteranopes')
    
    save(fullfile(savePath, 'MaxLMSDirection.mat'), 'MaxLMSDirection');
    save(fullfile(savePath, 'MaxLMSBackground.mat'), 'MaxLMSBackground');
end

if strcmp(protocolParams.protocol, 'SquintToPulse') || strcmp(protocolParams.protocol, 'Screening') || strcmp(protocolParams.protocol, 'Deuteranopes')
    
    save(fullfile(savePath, 'LightFluxBackground.mat'), 'LightFluxBackground');
    save(fullfile(savePath, 'LightFluxDirection.mat'), 'LightFluxDirection');
end

end