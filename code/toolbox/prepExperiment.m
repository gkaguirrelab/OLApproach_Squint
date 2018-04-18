function [ modulationData, ol, radiometer, calibration, protocolParams ] = prepExperiment(protocolParams, varargin)




%% get information about the subject we're working with
commandwindow;
protocolParams.observerID = GetWithDefault('>> Enter <strong>observer name</strong>', 'HERO_xxxx');
protocolParams.observerAgeInYrs = GetWithDefault('>> Enter <strong>observer age</strong>:', 32);
protocolParams.sessionName = GetWithDefault('>> Enter <strong>session number</strong>:', 'session_1');
protocolParams.todayDate = datestr(now, 'yyyy-mm-dd');


%% Open the OneLight
ol = OneLight('simulate',protocolParams.simulate.oneLight,'plotWhenSimulating',protocolParams.simulate.makePlots); drawnow;

%% Grab the relevant calibration
calibration = OLGetCalibrationStructure('CalibrationType',protocolParams.calibrationType,'CalibrationDate','latest');

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

%% open the session log
protocolParams = OLSessionLog(protocolParams,'OLSessionInit');

%% Make nominal direction objects, containing nominal primaries
MaxMelParams = OLDirectionParamsFromName('MaxMel_unipolar_275_60_667', 'alternateDictionaryFunc', protocolParams.directionsDictionary);
[ MaxMelDirection, MaxMelBackground ] = OLDirectionNominalFromParams(MaxMelParams, calibration, 'observerAge',protocolParams.observerAgeInYrs);
MaxMelDirection.describe.observerAge = protocolParams.observerAgeInYrs;
MaxMelDirection.describe.photoreceptorClasses = MaxMelDirection.describe.directionParams.photoreceptorClasses;
MaxMelDirection.describe.T_receptors = MaxMelDirection.describe.directionParams.T_receptors;

MaxLMSParams = OLDirectionParamsFromName('MaxLMS_unipolar_275_60_667', 'alternateDictionaryFunc', protocolParams.directionsDictionary);
[ MaxLMSDirection, MaxLMSBackground ] = OLDirectionNominalFromParams(MaxLMSParams, calibration, 'observerAge',protocolParams.observerAgeInYrs);
MaxLMSDirection.describe.observerAge = protocolParams.observerAgeInYrs;
MaxLMSDirection.describe.photoreceptorClasses = MaxLMSDirection.describe.directionParams.photoreceptorClasses;
MaxLMSDirection.describe.T_receptors = MaxLMSDirection.describe.directionParams.T_receptors;

LightFluxParams = OLDirectionParamsFromName('LightFlux_UnipolarBase', 'alternateDictionaryFunc', protocolParams.directionsDictionary);
LightFluxParams.backgroundParams = OLBackgroundParamsFromName(LightFluxParams.backgroundName, 'alternateDictionaryFunc', protocolParams.backgroundsDictionary);
[ LightFluxDirection, LightFluxBackground ] = OLDirectionNominalFromParams(LightFluxParams, calibration);
LightFluxDirection.describe.observerAge = protocolParams.observerAgeInYrs;
LightFluxDirection.describe.photoreceptorClasses = MaxMelDirection.describe.directionParams.photoreceptorClasses;
LightFluxDirection.describe.T_receptors = MaxMelDirection.describe.directionParams.T_receptors;

%% Validate prior to direction correction
T_receptors = MaxMelDirection.describe.directionParams.T_receptors; % the T_receptors will be the same for each direction, so just grab one
for ii = 1:protocolParams.nValidationsPerDirection
    
    OLValidateDirection(MaxMelDirection, MaxMelBackground, ol, radiometer, 'receptors', T_receptors, 'label', 'precorrection');
    postreceptoralContrast = ComputePostreceptoralContrastsFromLMSContrasts(MaxMelDirection.describe.validation(ii).contrastActual(1:3,1));
    MaxMelDirection.describe.validation(ii).postreceptoralContrastActual = postreceptoralContrast;
    
    OLValidateDirection(MaxLMSDirection, MaxLMSBackground, ol, radiometer, 'receptors', T_receptors, 'label', 'precorrection');
    postreceptoralContrast = ComputePostreceptoralContrastsFromLMSContrasts(MaxLMSDirection.describe.validation(ii).contrastActual(1:3,1));
    MaxLMSDirection.describe.validation(ii).postreceptoralContrastActual = postreceptoralContrast;
    
    OLValidateDirection(LightFluxDirection, LightFluxBackground, ol, radiometer, 'receptors', T_receptors, 'label', 'precorrection');
    postreceptoralContrast = ComputePostreceptoralContrastsFromLMSContrasts(LightFluxDirection.describe.validation(ii).contrastActual(1:3,1));
    LightFluxDirection.describe.validation(ii).postreceptoralContrastActual = postreceptoralContrast;
end

%% Check if these nominal spectra meet exclusion criteria

MaxMelFigure = figure;
MaxMelValidation = summarizeValidation(MaxMelDirection, 'whichValidationPrefix', 'precorrection');
MaxMelPassStatus = applyValidationExclusionCriteria(MaxMelValidation, MaxMelDirection);

MaxLMSFigure = figure;
MaxLMSValidation = summarizeValidation(MaxLMSDirection, 'whichValidationPrefix', 'precorrection');
MaxLMSPassStatus = applyValidationExclusionCriteria(MaxLMSValidation, MaxLMSDirection);

LightFluxFigure = figure;
LightFluxValidation = summarizeValidation(LightFluxDirection, 'whichValidationPrefix', 'precorrection');
LightFluxPassStatus = applyValidationExclusionCriteria(LightFluxValidation, LightFluxDirection);

%% Correct the direction objects

if ~(protocolParams.simulate.radiometer)
    % only correct if we're not simulating the radiometer
    %if MaxMelPassStatus == 0
        OLCorrectDirection(MaxMelDirection, MaxMelBackground, ol, radiometer, 'legacyMode', true);
        for ii = length(MaxMelDirection.describe.validation)+1:length(MaxMelDirection.describe.validation)+protocolParams.nValidationsPerDirection
            OLValidateDirection(MaxMelDirection, MaxMelBackground, ol, radiometer, 'receptors', T_receptors, 'label', 'postcorrection');
            postreceptoralContrast = ComputePostreceptoralContrastsFromLMSContrasts(MaxMelDirection.describe.validation(ii).contrastActual(1:3,1));
            MaxMelDirection.describe.validation(ii).postreceptoralContrastActual = postreceptoralContrast;
        end
        MaxMelPostFigure = figure;
        MaxMelPostValidation = summarizeValidation(MaxMelDirection, 'whichValidationPrefix', 'postcorrection', 'plot', 'off');
        MaxMelPassStatus = applyValidationExclusionCriteria(MaxMelPostValidation, MaxMelDirection);
        MaxMelPostValidation = summarizeValidation(MaxMelDirection);
        
   % end
    
    
    %if MaxLMSPassStatus == 0
        OLCorrectDirection(MaxLMSDirection, MaxLMSBackground, ol, radiometer, 'legacyMode', true);
        for ii = length(MaxLMSDirection.describe.validation)+1:length(MaxLMSDirection.describe.validation)+protocolParams.nValidationsPerDirection
            OLValidateDirection(MaxLMSDirection, MaxLMSBackground, ol, radiometer, 'receptors', T_receptors, 'label', 'postcorrection');
            postreceptoralContrast = ComputePostreceptoralContrastsFromLMSContrasts(MaxLMSDirection.describe.validation(ii).contrastActual(1:3,1));
            MaxLMSDirection.describe.validation(ii).postreceptoralContrastActual = postreceptoralContrast;
        end
        MaxLMSPostFigure = figure;
        MaxLMSPostValidation = summarizeValidation(MaxLMSDirection, 'whichValidationPrefix', 'postcorrection', 'plot', 'off');
        MaxLMSPassStatus = applyValidationExclusionCriteria(MaxLMSPostValidation, MaxLMSDirection);
        MaxLMSPostValidation = summarizeValidation(MaxLMSDirection);
        
    %end
    
    %if LightFluxPassStatus == 0
        OLCorrectDirection(LightFluxDirection, LightFluxBackground, ol, radiometer, 'legacyMode', true);
        for ii = length(LightFluxDirection.describe.validation)+1:length(LightFluxDirection.describe.validation)+protocolParams.nValidationsPerDirection
            OLValidateDirection(LightFluxDirection, LightFluxBackground, ol, radiometer, 'receptors', T_receptors, 'label', 'postcorrection');
            postreceptoralContrast = ComputePostreceptoralContrastsFromLMSContrasts(LightFluxDirection.describe.validation(ii).contrastActual(1:3,1));
            LightFluxDirection.describe.validation(ii).postreceptoralContrastActual = postreceptoralContrast;
        end
        LightFluxPostFigure = figure;
        LightFluxPostValidation = summarizeValidation(LightFluxDirection, 'whichValidationPrefix', 'postcorrection', 'plot', 'off');
        LightFluxPassStatus = applyValidationExclusionCriteria(LightFluxPostValidation, LightFluxDirection);
        LightFluxPostValidation = summarizeValidation(LightFluxDirection);
        
    %end
end

%% Check if we have god modulations
if MaxMelPassStatus == 1
    fprintf('Mel modulations are good\n');
else
    fprintf('<strong>Mel modulations are poor</strong>\n');
end

if MaxLMSPassStatus == 1
    fprintf('LMS modulations are good\n');
else
    fprintf('<strong>LMS modulations are poor</strong>\n');
end

if LightFluxPassStatus == 1
    fprintf('Light flux modulations are good\n');
else
    fprintf('<strong>Light flux  modulations are poor</strong>\n');
end

if MaxMelPassStatus == 1 && MaxLMSPassStatus == 1 && LightFluxPassStatus == 1
    fprintf('***We have good modulations and are ready for the experiment***\n');
else
    fprintf('<strong>***Modulations are poor, we have to figure something out***</strong>\n');
end

%% save directions and backgrounds
savePath = fullfile(getpref('OLApproach_Squint', 'DataPath'), 'Experiments', protocolParams.approach, protocolParams.protocol, 'DirectionObjects', protocolParams.observerID, [protocolParams.todayDate, '_', protocolParams.sessionName]);
if ~exist(savePath,'dir')
    mkdir(savePath);
end
save(fullfile(savePath, 'MaxMelDirection.mat'), 'MaxMelDirection');
save(fullfile(savePath, 'MaxLMSDirection.mat'), 'MaxLMSDirection');
save(fullfile(savePath, 'LightFluxDirection.mat'), 'LightFluxDirection');
save(fullfile(savePath, 'MaxMelBackground.mat'), 'MaxMelBackground');
save(fullfile(savePath, 'MaxLMSBackground.mat'), 'MaxLMSBackground');
save(fullfile(savePath, 'LightFluxBackground.mat'), 'LightFluxBackground');

%% Make waveform
waveformParams = OLWaveformParamsFromName('MaxContrastPulse'); % get generic pulse parameters
waveformParams.stimulusDuration = 4; % 4 second pulses
[Pulse400Waveform, pulseTimestep] = OLWaveformFromParams(waveformParams); % 4 second pulse waveform max contrast
Pulse200Waveform = Pulse400Waveform / 2;
Pulse100Waveform = Pulse400Waveform / 4;

%% Make the modulation starts and stops
Mel400PulseModulation = OLAssembleModulation([MaxMelBackground, MaxMelDirection], [ones(1, length(Pulse400Waveform)); Pulse400Waveform]);
Mel200PulseModulation = OLAssembleModulation([MaxMelBackground, MaxMelDirection], [ones(1, length(Pulse200Waveform)); Pulse200Waveform]);
Mel100PulseModulation = OLAssembleModulation([MaxMelBackground, MaxMelDirection], [ones(1, length(Pulse100Waveform)); Pulse100Waveform]);

LMS400PulseModulation = OLAssembleModulation([MaxLMSBackground, MaxLMSDirection], [ones(1, length(Pulse400Waveform)); Pulse400Waveform]);
LMS200PulseModulation = OLAssembleModulation([MaxLMSBackground, MaxLMSDirection], [ones(1, length(Pulse200Waveform)); Pulse200Waveform]);
LMS100PulseModulation = OLAssembleModulation([MaxLMSBackground, MaxLMSDirection], [ones(1, length(Pulse100Waveform)); Pulse100Waveform]);

LightFlux400PulseModulation = OLAssembleModulation([LightFluxBackground, LightFluxDirection], [ones(1, length(Pulse400Waveform)); Pulse400Waveform]);
LightFlux200PulseModulation = OLAssembleModulation([LightFluxBackground, LightFluxDirection], [ones(1, length(Pulse200Waveform)); Pulse200Waveform]);
LightFlux100PulseModulation = OLAssembleModulation([LightFluxBackground, LightFluxDirection], [ones(1, length(Pulse100Waveform)); Pulse100Waveform]);

%% Define all modulations
% Mel modulations
Mel400PulseModulationData.modulationParams.direction = "Melanopsin 400% contrast";
Mel400PulseModulationData.modulation = Mel400PulseModulation;
[Mel400PulseModulationData.modulation.background.starts, Mel400PulseModulationData.modulation.background.stops] = OLPrimaryToStartsStops(MaxMelBackground.differentialPrimaryValues, calibration);
Mel400PulseModulationData.modulationParams.stimulusDuration = waveformParams.stimulusDuration;
Mel400PulseModulationData.modulationParams.timeStep = pulseTimestep;

Mel200PulseModulationData.modulationParams.direction = "Melanopsin 200% contrast";
Mel200PulseModulationData.modulation = Mel200PulseModulation;
[Mel200PulseModulationData.modulation.background.starts, Mel200PulseModulationData.modulation.background.stops] = OLPrimaryToStartsStops(MaxMelBackground.differentialPrimaryValues, calibration);
Mel200PulseModulationData.modulationParams.stimulusDuration = waveformParams.stimulusDuration;
Mel200PulseModulationData.modulationParams.timeStep = pulseTimestep;

Mel100PulseModulationData.modulationParams.direction = "Melanopsin 100% contrast";
Mel100PulseModulationData.modulation = Mel100PulseModulation;
[Mel100PulseModulationData.modulation.background.starts, Mel100PulseModulationData.modulation.background.stops] = OLPrimaryToStartsStops(MaxMelBackground.differentialPrimaryValues, calibration);
Mel100PulseModulationData.modulationParams.stimulusDuration = waveformParams.stimulusDuration;
Mel100PulseModulationData.modulationParams.timeStep = pulseTimestep;

% LMS modulations
LMS400PulseModulationData.modulationParams.direction = "LMS 400% contrast";
LMS400PulseModulationData.modulation = LMS400PulseModulation;
[LMS400PulseModulationData.modulation.background.starts, LMS400PulseModulationData.modulation.background.stops] = OLPrimaryToStartsStops(MaxLMSBackground.differentialPrimaryValues, calibration);
LMS400PulseModulationData.modulationParams.stimulusDuration = waveformParams.stimulusDuration;
LMS400PulseModulationData.modulationParams.timeStep = pulseTimestep;

LMS200PulseModulationData.modulationParams.direction = "LMS 200% contrast";
LMS200PulseModulationData.modulation = LMS200PulseModulation;
[LMS200PulseModulationData.modulation.background.starts, LMS200PulseModulationData.modulation.background.stops] = OLPrimaryToStartsStops(MaxLMSBackground.differentialPrimaryValues, calibration);
LMS200PulseModulationData.modulationParams.stimulusDuration = waveformParams.stimulusDuration;
LMS200PulseModulationData.modulationParams.timeStep = pulseTimestep;

LMS100PulseModulationData.modulationParams.direction = "LMS 100% contrast";
LMS100PulseModulationData.modulation = LMS100PulseModulation;
[LMS100PulseModulationData.modulation.background.starts, LMS100PulseModulationData.modulation.background.stops] = OLPrimaryToStartsStops(MaxLMSBackground.differentialPrimaryValues, calibration);
LMS100PulseModulationData.modulationParams.stimulusDuration = waveformParams.stimulusDuration;
LMS100PulseModulationData.modulationParams.timeStep = pulseTimestep;

% Mel LMS Modulations
LightFlux400PulseModulationData.modulationParams.direction = "Light flux 400% contrast";
LightFlux400PulseModulationData.modulation = LightFlux400PulseModulation;
[LightFlux400PulseModulationData.modulation.background.starts, LightFlux400PulseModulationData.modulation.background.stops] = OLPrimaryToStartsStops(LightFluxBackground.differentialPrimaryValues, calibration);
LightFlux400PulseModulationData.modulationParams.stimulusDuration = waveformParams.stimulusDuration;
LightFlux400PulseModulationData.modulationParams.timeStep = pulseTimestep;

LightFlux200PulseModulationData.modulationParams.direction = "Light flux 200% contrast";
LightFlux200PulseModulationData.modulation = LightFlux200PulseModulation;
[LightFlux200PulseModulationData.modulation.background.starts, LightFlux200PulseModulationData.modulation.background.stops] = OLPrimaryToStartsStops(LightFluxBackground.differentialPrimaryValues, calibration);
LightFlux200PulseModulationData.modulationParams.stimulusDuration = waveformParams.stimulusDuration;
LightFlux200PulseModulationData.modulationParams.timeStep = pulseTimestep;

LightFlux100PulseModulationData.modulationParams.direction = "Light flux 100% contrast";
LightFlux100PulseModulationData.modulation = LightFlux100PulseModulation;
[LightFlux100PulseModulationData.modulation.background.starts, LightFlux100PulseModulationData.modulation.background.stops] = OLPrimaryToStartsStops(LightFluxBackground.differentialPrimaryValues, calibration);
LightFlux100PulseModulationData.modulationParams.stimulusDuration = waveformParams.stimulusDuration;
LightFlux100PulseModulationData.modulationParams.timeStep = pulseTimestep;

% save modulations
savePath = fullfile(getpref('OLApproach_Squint', 'DataPath'), 'Experiments', protocolParams.approach, protocolParams.protocol, 'ModulationStructs', protocolParams.observerID, protocolParams.todayDate);
if ~exist(savePath,'dir')
    mkdir(savePath);
end
save(fullfile(savePath, 'Mel400PulseModulationData.mat'), 'Mel400PulseModulationData');
save(fullfile(savePath, 'Mel200PulseModulationData.mat'), 'Mel200PulseModulationData');
save(fullfile(savePath, 'Mel100PulseModulationData.mat'), 'Mel100PulseModulationData');

save(fullfile(savePath, 'LMS400PulseModulationData.mat'), 'LMS400PulseModulationData');
save(fullfile(savePath, 'LMS200PulseModulationData.mat'), 'LMS200PulseModulationData');
save(fullfile(savePath, 'LMS100PulseModulationData.mat'), 'LMS100PulseModulationData');

save(fullfile(savePath, 'LightFlux400PulseModulationData.mat'), 'LightFlux400PulseModulationData');
save(fullfile(savePath, 'LightFlux200PulseModulationData.mat'), 'LightFlux200PulseModulationData');
save(fullfile(savePath, 'LightFlux100PulseModulationData.mat'), 'LightFlux100PulseModulationData');

%% Package up the output
modulationData = [Mel400PulseModulationData; Mel200PulseModulationData; Mel100PulseModulationData; ...
            LMS400PulseModulationData; LMS200PulseModulationData; LMS100PulseModulationData; ...
            LightFlux400PulseModulationData; LightFlux200PulseModulationData; LightFlux100PulseModulationData];
        


end % end function