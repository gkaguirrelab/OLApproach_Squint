function [ modulationData, ol, radiometer, calibration, protocolParams ] = prepExperiment(protocolParams, varargin)
% A function that controls much of the pre-experiment behavior for
% OLApproach_Squint Experiments

% Syntax:
%  [ modulationData, ol, radiometer, calibration, protocolParams ] = prepExperiment(protocolParams);

% Description:
%   This function performs a number of tasks meant to be accomplished prior
%   to subject arrival for an experiment under the OLApproach_Squint
%   umbrella. These tasks include 1) generation of nominal stimuli, 2)
%   validation measurements prior to stimulus correction, 3) direction
%   correction or spectrum seeking, 4) and generation of modulations.

% Inputs:
%   protocolParams        - A struct defining specifics about the
%                           experiment. Relevant fields include:
%                           information about the subject, protocol name,
%                           calibration name, among others.
%
% Optional key-value pairs:
%   observerID            - A string defining the observerID (i.e.
%                           HERO_HMM) for the given subject
%   observerAgeInYrs      - A number defining the age of the relevant
%                           observer, in years
%   sessionName           - A string defining the sessionName of the
%                           relevant session (i.e. session_1)
%   skipPause             - A logical to control whether to pause prior to
%                           beginning of validation. The default is set to
%                           false, meaning that the routine will pause just
%                           prior to validation to make sure we have all of
%                           the equipment set up. Set to true, for example,
%                           when wanting to loop over multiple iterations
%                           of this for torture testing purposes.
%
% Outputs:
%   modulationData          - A Nx1 element vector where each element
%                             is the modulation of a different stimulus type.
%  ol                       - The instantiated OneLight object
%  radiometer               - The instantiated radiometer object
%  calibration              - A structure that defines the relevant
%                             calibration
%  protocolParams           - A structure that defines the specifics of the
%                             experiment, which might be appended over the
%                             course of this routine to include subject
%                             specifics (obseverID, observerAgeInYrs,
%                             sessionName, for example)


p = inputParser; p.KeepUnmatched = true;

p.addParameter('observerID',[],@ischar);
p.addParameter('observerAgeInYrs',[],@isnumeric);
p.addParameter('sessionName',[],@ischar);
p.addParameter('skipPause',false, @islogical);



p.parse(varargin{:});

%% Get information about the subject we're working with
commandwindow;
if isempty(p.Results.observerID)
    protocolParams.observerID = GetWithDefault('>> Enter <strong>observer name</strong>', 'HERO_xxxx');
else
    protocolParams.observerID = p.Results.observerID;
end

if isempty(p.Results.observerAgeInYrs)
    protocolParams.observerAgeInYrs = GetWithDefault('>> Enter <strong>observer age</strong>:', 32);
else
    protocolParams.observerAgeInYrs = p.Results.observerAgeInYrs;
end

if isempty(p.Results.sessionName)
    protocolParams.sessionName = GetWithDefault('>> Enter <strong>session number</strong>:', 'session_1');
else
    protocolParams.sessionName = p.Results.sessionName;
end

protocolParams.todayDate = datestr(now, 'yyyy-mm-dd');

%% Prep to save
savePath = fullfile(getpref('OLApproach_Squint', 'DataPath'), 'Experiments', protocolParams.approach, protocolParams.protocol, 'DirectionObjects', protocolParams.observerID, [protocolParams.todayDate, '_', protocolParams.sessionName]);
if ~exist(savePath,'dir')
    mkdir(savePath);
end


%% Query user whether to take temperature measurements
takeTemperatureMeasurements = true;
%takeTemperatureMeasurements = GetWithDefault('Take Temperature Measurements ?', false);
if (takeTemperatureMeasurements ~= true) && (takeTemperatureMeasurements ~= 1)
    takeTemperatureMeasurements = false;
else
    takeTemperatureMeasurements = true;
end

if (takeTemperatureMeasurements)
    % Gracefully attempt to open the LabJack
    [takeTemperatureMeasurements, quitNow, theLJdev] = OLCalibrator.OpenLabJackTemperatureProbe(takeTemperatureMeasurements);
    if (quitNow)
        return;
    end
else
    theLJdev = [];
end

%% Set flag indicating whether to measure state tracking SPDs in OLValidateDirection() and OLCorrectDirection()
measureStateTrackingSPDs = true;


%% Grab the relevant calibration
calibration = OLGetCalibrationStructure('CalibrationType',protocolParams.calibrationType,'CalibrationDate','latest');



%% open the session log
protocolParams = OLSessionLog(protocolParams,'OLSessionInit');

%% Make nominal direction objects, containing nominal primaries
% but which directions we have to make depends on the protocol
% for the SquintToPusle protocol, we want Mel, LMS, and light flux
% for screening, we just want light flux

if strcmp(protocolParams.protocol, 'SquintToPulse') || strcmp(protocolParams.protocol, 'Screening')
    % make the Mel params for screening just so we have the T_receptors and
    % photoreceptorClasses subfields
    MaxMelParams = OLDirectionParamsFromName('MaxMel_chrom_unipolar_275_60_4000', 'alternateDictionaryFunc', protocolParams.directionsDictionary);
    [ MaxMelDirection, MaxMelBackground ] = OLDirectionNominalFromParams(MaxMelParams, calibration, 'observerAge',protocolParams.observerAgeInYrs, 'alternateBackgroundDictionaryFunc', protocolParams.backgroundsDictionary);
    MaxMelDirection.describe.observerAge = protocolParams.observerAgeInYrs;
    MaxMelDirection.describe.photoreceptorClasses = MaxMelDirection.describe.directionParams.photoreceptorClasses;
    MaxMelDirection.describe.T_receptors = MaxMelDirection.describe.directionParams.T_receptors;
end

if strcmp(protocolParams.protocol, 'SquintToPulse')
    MaxLMSParams = OLDirectionParamsFromName('MaxLMS_chrom_unipolar_275_60_4000', 'alternateDictionaryFunc', protocolParams.directionsDictionary);
    [ MaxLMSDirection, MaxLMSBackground ] = OLDirectionNominalFromParams(MaxLMSParams, calibration, 'observerAge',protocolParams.observerAgeInYrs, 'alternateBackgroundDictionaryFunc', protocolParams.backgroundsDictionary);
    MaxLMSDirection.describe.observerAge = protocolParams.observerAgeInYrs;
    MaxLMSDirection.describe.photoreceptorClasses = MaxLMSDirection.describe.directionParams.photoreceptorClasses;
    MaxLMSDirection.describe.T_receptors = MaxLMSDirection.describe.directionParams.T_receptors;
end

if strcmp(protocolParams.protocol, 'SquintToPulse') || strcmp(protocolParams.protocol, 'Screening')
    
    LightFluxParams = OLDirectionParamsFromName('LightFlux_chrom_unipolar_275_60_4000', 'alternateDictionaryFunc', protocolParams.directionsDictionary);
    
    % playing around with the light flux params -- these are the specific
    % parameters David played with. with the most recent calibration for BoxD
    % with the short liquid light guide and ND0.1, these gave reasonable
    % modulations
    
    %     whichXYZ = 'xyzCIEPhys10';
    %     LightFluxParams.desiredxy = [0.60 0.38];
    %     LightFluxParams.whichXYZ = whichXYZ;
    %     LightFluxParams.desiredMaxContrast = 4;
    %     LightFluxParams.desiredBackgroundLuminance = 221.45;
    %
    %     LightFluxParams.search.primaryHeadroom = 0.000;
    %     LightFluxParams.search.primaryTolerance = 1e-6;
    %     LightFluxParams.search.checkPrimaryOutOfRange = true;
    %     LightFluxParams.search.lambda = 0;
    %     LightFluxParams.search.spdToleranceFraction = 30e-5;
    %     LightFluxParams.search.chromaticityTolerance = 0.1;
    %     LightFluxParams.search.optimizationTarget = 'maxContrast';
    %     LightFluxParams.search.primaryHeadroomForInitialMax = 0.000;
    %     LightFluxParams.search.maxSearchIter = 3000;
    %     LightFluxParams.search.verbose = false;
    
    [ LightFluxDirection, LightFluxBackground ] = OLDirectionNominalFromParams(LightFluxParams, calibration, 'alternateBackgroundDictionaryFunc', protocolParams.backgroundsDictionary);
    LightFluxDirection.describe.observerAge = protocolParams.observerAgeInYrs;
    LightFluxDirection.describe.photoreceptorClasses = MaxMelDirection.describe.directionParams.photoreceptorClasses;
    LightFluxDirection.describe.T_receptors = MaxMelDirection.describe.directionParams.T_receptors;
end

if strcmp(protocolParams.protocol, 'Deuteranopes')
    
    % Melanopsin directed stimulus
    % start with base melanopsin params
    MaxMelParams = OLDirectionParamsFromName('MaxMel_unipolar_275_60_667', 'alternateDictionaryFunc', 'OLDirectionParamsDictionary_Squint');
    
    % adjust to say ignore the M cone
    % for the direction
    MaxMelParams.whichReceptorsToIgnore = [2];
    % for the background. accomplish this by using special background that's
    % already defined to have M cone ignored
    MaxMelParams.backgroundName = 'MelanopsinDirectedForDeuteranopes_275_60_667';
    
    % aim for a higher contrast. I have plugged in here a max contrast of 0.9
    % specified in bipolar contrast, which equates to 1800% contrast for
    % unipolar modulations. we won't get there, but we'll aim for it.
    % I will note that I'm not sure what the difference between these two
    % fields are supposed to represent
    MaxMelParams.baseModulationContrast = OLUnipolarToBipolarContrast(12);
    MaxMelParams.modulationContrast = OLUnipolarToBipolarContrast(12);
    
    % make rest of the nominal modulations
    [ MaxMelDirection, MaxMelBackground ] = OLDirectionNominalFromParams(MaxMelParams, calibration, 'observerAge',observerAge, 'alternateBackgroundDictionaryFunc', 'OLBackgroundParamsDictionary_Squint');
    MaxMelDirection.describe.observerAge = observerAge;
    MaxMelDirection.describe.photoreceptorClasses = MaxMelDirection.describe.directionParams.photoreceptorClasses;
    MaxMelDirection.describe.T_receptors = MaxMelDirection.describe.directionParams.T_receptors;
    
    % LMS directed stimulus
    % start with base LMS prams
    MaxLMSParams = OLDirectionParamsFromName('MaxLMS_unipolar_275_60_667', 'alternateDictionaryFunc', 'OLDirectionParamsDictionary_Squint');
    
    % aim for a higher contrast. I have plugged in here a max contrast of 0.9
    % specified in bipolar contrast, which equates to 1800% contrast for
    % unipolar modulations. we won't get there, but we'll aim for it.
    % I will note that I'm not sure what the difference between these two
    % fields are supposed to represent
    MaxLMSParams.baseModulationContrast = OLUnipolarToBipolarContrast(12);
    MaxLMSParams.modulationContrast = OLUnipolarToBipolarContrast(12);
    
    % adjust to say ignore the M cone
    % for the direction
    MaxLMSParams.modulationContrast = [MaxLMSParams.baseModulationContrast MaxLMSParams.baseModulationContrast];
    MaxLMSParams.whichReceptorsToIsolate = [1 3];
    MaxLMSParams.whichReceptorsToIgnore = [2];
    % for the background
    MaxLMSParams.backgroundName = 'LMSDirectedForDeuteranopes_275_60_667';
    
    [MaxLMSDirection, MaxLMSBackground ] = OLDirectionNominalFromParams(MaxLMSParams, calibration, 'observerAge',observerAge, 'alternateBackgroundDictionaryFunc', 'OLBackgroundParamsDictionary_Squint');
    MaxLMSDirection.describe.observerAge = observerAge;
    MaxLMSDirection.describe.photoreceptorClasses = MaxLMSDirection.describe.directionParams.photoreceptorClasses;
    MaxLMSDirection.describe.T_receptors = MaxLMSDirection.describe.directionParams.T_receptors;
    
    % LightFlux directed stimulus
    % start with base LMS prams
    LightFluxParams = OLDirectionParamsFromName('MaxLMS_unipolar_275_60_667', 'alternateDictionaryFunc', 'OLDirectionParamsDictionary_Squint');
    
    % aim for a higher contrast. I have plugged in here a max contrast of 0.9
    % specified in bipolar contrast, which equates to 1800% contrast for
    % unipolar modulations. we won't get there, but we'll aim for it.
    % I will note that I'm not sure what the difference between these two
    % fields are supposed to represent
    LightFluxParams.baseModulationContrast = OLUnipolarToBipolarContrast(12);
    LightFluxParams.modulationContrast = OLUnipolarToBipolarContrast(12);
    
    % adjust to say ignore the M cone
    % for the direction
    LightFluxParams.modulationContrast = [LightFluxParams.baseModulationContrast LightFluxParams.baseModulationContrast LightFluxParams.baseModulationContrast];
    LightFluxParams.whichReceptorsToIsolate = [1 3 4];
    LightFluxParams.whichReceptorsToIgnore = [2];
    % for the background
    LightFluxParams.backgroundName = 'LightFluxForDeuteranopes_275_60_667';
    
    [LightFluxDirection, LightFluxBackground ] = OLDirectionNominalFromParams(LightFluxParams, calibration, 'observerAge',observerAge, 'alternateBackgroundDictionaryFunc', 'OLBackgroundParamsDictionary_Squint');
    LightFluxDirection.describe.observerAge = observerAge;
    LightFluxDirection.describe.photoreceptorClasses = LightFluxDirection.describe.directionParams.photoreceptorClasses;
    LightFluxDirection.describe.T_receptors = LightFluxDirection.describe.directionParams.T_receptors;
    
    
end

%% Open the OneLight
ol = OneLight('simulate',protocolParams.simulate.oneLight,'plotWhenSimulating',protocolParams.simulate.makePlots); drawnow;

%% Let user get the radiometer set up
if ~protocolParams.simulate.radiometer
    radiometerPauseDuration = 0;
    ol.setAll(true);
    commandwindow;
    fprintf('- Focus the radiometer and press enter to pause %d seconds and start measuring.\n', radiometerPauseDuration);
    if ~(p.Results.skipPause)
        input('');
    end
    ol.setAll(false);
    pause(radiometerPauseDuration);
    radiometer = OLOpenSpectroRadiometerObj('PR-670');
else
    radiometer = [];
end
%% Validate prior to direction correction
T_receptors = MaxMelDirection.describe.directionParams.T_receptors; % the T_receptors will be the same for each direction, so just grab one
for ii = 1:protocolParams.nValidationsPerDirection
    
    if strcmp(protocolParams.protocol, 'SquintToPulse') || strcmp(protocolParams.protocol, 'Deuteranopes')
        OLValidateDirection(MaxMelDirection, MaxMelBackground, ol, radiometer, ...
            'receptors', T_receptors, 'label', 'precorrection', ...
            'temperatureProbe', theLJdev, ...
            'measureStateTrackingSPDs', measureStateTrackingSPDs);
        postreceptoralContrast = ComputePostreceptoralContrastsFromLMSContrasts(MaxMelDirection.describe.validation(ii).contrastActual(1:3,1));
        MaxMelDirection.describe.validation(ii).postreceptoralContrastActual = postreceptoralContrast;
        save(fullfile(savePath, 'MaxMelDirection.mat'), 'MaxMelDirection');
        save(fullfile(savePath, 'MaxMelBackground.mat'), 'MaxMelBackground');
    end
    
    
    if strcmp(protocolParams.protocol, 'SquintToPulse') || strcmp(protocolParams.protocol, 'Deuteranopes')
        OLValidateDirection(MaxLMSDirection, MaxLMSBackground, ol, radiometer, ...
            'receptors', T_receptors, 'label', 'precorrection', ...
            'temperatureProbe', theLJdev, ...
            'measureStateTrackingSPDs', measureStateTrackingSPDs);
        postreceptoralContrast = ComputePostreceptoralContrastsFromLMSContrasts(MaxLMSDirection.describe.validation(ii).contrastActual(1:3,1));
        MaxLMSDirection.describe.validation(ii).postreceptoralContrastActual = postreceptoralContrast;
        save(fullfile(savePath, 'MaxLMSDirection.mat'), 'MaxLMSDirection');
        save(fullfile(savePath, 'MaxLMSBackground.mat'), 'MaxLMSBackground');
    end
    
    if strcmp(protocolParams.protocol, 'SquintToPulse') || strcmp(protocolParams.protocol, 'Screening') || strcmp(protocolParams.protocol, 'Deuteranopes')
        OLValidateDirection(LightFluxDirection, LightFluxBackground, ol, radiometer, ...
            'receptors', T_receptors, 'label', 'precorrection', ...
            'temperatureProbe', theLJdev, ...
            'measureStateTrackingSPDs', measureStateTrackingSPDs);
        postreceptoralContrast = ComputePostreceptoralContrastsFromLMSContrasts(LightFluxDirection.describe.validation(ii).contrastActual(1:3,1));
        LightFluxDirection.describe.validation(ii).postreceptoralContrastActual = postreceptoralContrast;
        save(fullfile(savePath, 'LightFluxBackground.mat'), 'LightFluxBackground');
        save(fullfile(savePath, 'LightFluxDirection.mat'), 'LightFluxDirection');
    end
    

end

%% Check if these nominal spectra meet exclusion criteria

if strcmp(protocolParams.protocol, 'SquintToPulse')
    MaxMelFigure = figure;
    MaxMelValidation = summarizeValidation(MaxMelDirection, 'whichValidationPrefix', 'precorrection');
    MaxMelPassStatus = applyValidationExclusionCriteria(MaxMelValidation, MaxMelDirection);
end

if strcmp(protocolParams.protocol, 'SquintToPulse')
    
    MaxLMSFigure = figure;
    MaxLMSValidation = summarizeValidation(MaxLMSDirection, 'whichValidationPrefix', 'precorrection');
    MaxLMSPassStatus = applyValidationExclusionCriteria(MaxLMSValidation, MaxLMSDirection);
end

if strcmp(protocolParams.protocol, 'SquintToPulse') || strcmp(protocolParams.protocol, 'Screening')
    LightFluxFigure = figure;
    LightFluxValidation = summarizeValidation(LightFluxDirection, 'whichValidationPrefix', 'precorrection');
    LightFluxPassStatus = applyValidationExclusionCriteria(LightFluxValidation, LightFluxDirection);
end

%% Correct the direction objects

if ~(protocolParams.simulate.radiometer)
    % only correct if we're not simulating the radiometer
    lightlevelScalar = OLMeasureLightlevelScalar(ol,calibration,radiometer);
    fprintf("%.3f.\n",lightlevelScalar);
    
    nullDirection = OLDirection_unipolar.Null(calibration);
    
    if strcmp(protocolParams.protocol, 'SquintToPulse') || strcmp(protocolParams.protocol, 'Deuteranopes')
        %if MaxMelPassStatus == 0
        OLCorrectDirection(MaxMelBackground, nullDirection, ol, radiometer, ...
            'smoothness', 0.1, ...
            'temperatureProbe', theLJdev, ...
            'lightlevelScalar',lightlevelScalar,...
            'measureStateTrackingSPDs', measureStateTrackingSPDs);
        OLCorrectDirection(MaxMelDirection, MaxMelBackground, ol, radiometer, ...
            'smoothness', 0.1, ...
            'temperatureProbe', theLJdev, ...
            'lightlevelScalar',lightlevelScalar,...
            'measureStateTrackingSPDs', measureStateTrackingSPDs);
        for ii = length(MaxMelDirection.describe.validation)+1:length(MaxMelDirection.describe.validation)+protocolParams.nValidationsPerDirection
            OLValidateDirection(MaxMelDirection, MaxMelBackground, ol, radiometer, ...
                'receptors', T_receptors, 'label', 'postcorrection', ...
                'temperatureProbe', theLJdev, ...
                'measureStateTrackingSPDs', measureStateTrackingSPDs);
            postreceptoralContrast = ComputePostreceptoralContrastsFromLMSContrasts(MaxMelDirection.describe.validation(ii).contrastActual(1:3,1));
            MaxMelDirection.describe.validation(ii).postreceptoralContrastActual = postreceptoralContrast;
            save(fullfile(savePath, 'MaxMelDirection.mat'), 'MaxMelDirection');
            save(fullfile(savePath, 'MaxMelBackground.mat'), 'MaxMelBackground');
        end
        if strcmp(protocolParams.protocol, 'SquintToPulse')
            MaxMelPostFigure = figure;
            MaxMelPostValidation = summarizeValidation(MaxMelDirection, 'whichValidationPrefix', 'postcorrection', 'plot', 'off');
            MaxMelPassStatus = applyValidationExclusionCriteria(MaxMelPostValidation, MaxMelDirection);
            MaxMelPostValidation = summarizeValidation(MaxMelDirection);
        elseif strcmp(protocolParams.protocol, 'Deuteranopes')
            fprintf('\n<strong>For melanopsin stimuli:</strong>\n');
            fprintf('\tL Cone Contrast: %4.2f %%\n',  MaxMelDirection.describe.validation.contrastActual(1,1)*100);
            fprintf('\tS Cone Contrast: %4.2f %%\n',  MaxMelDirection.describe.validation.contrastActual(3,1)*100);
            fprintf('\tMelanopsin Contrast: %4.2f %%\n',  MaxMelDirection.describe.validation.contrastActual(4,1)*100);
        end
        %end
        
    end
    
    if strcmp(protocolParams.protocol, 'SquintToPulse') || strcmp(protocolParams.protocol, 'Deuteranopes')
        
        %if MaxLMSPassStatus == 0
        OLCorrectDirection(MaxLMSBackground, nullDirection, ol, radiometer, ...
            'smoothness', 0.1, ...
            'temperatureProbe', theLJdev, ...
            'lightlevelScalar',lightlevelScalar,...
            'measureStateTrackingSPDs', measureStateTrackingSPDs);
        OLCorrectDirection(MaxLMSDirection, MaxLMSBackground, ol, radiometer, ...
            'smoothness', 0.1, ...
            'temperatureProbe', theLJdev, ...
            'lightlevelScalar',lightlevelScalar,...
            'measureStateTrackingSPDs', measureStateTrackingSPDs);
        for ii = length(MaxLMSDirection.describe.validation)+1:length(MaxLMSDirection.describe.validation)+protocolParams.nValidationsPerDirection
            OLValidateDirection(MaxLMSDirection, MaxLMSBackground, ol, radiometer, ...
                'receptors', T_receptors, 'label', 'postcorrection', ...
                'temperatureProbe', theLJdev, ...
                'measureStateTrackingSPDs', measureStateTrackingSPDs);
            postreceptoralContrast = ComputePostreceptoralContrastsFromLMSContrasts(MaxLMSDirection.describe.validation(ii).contrastActual(1:3,1));
            MaxLMSDirection.describe.validation(ii).postreceptoralContrastActual = postreceptoralContrast;
            save(fullfile(savePath, 'MaxLMSDirection.mat'), 'MaxLMSDirection');
            save(fullfile(savePath, 'MaxLMSBackground.mat'), 'MaxLMSBackground');
        end
        if strcmp(protocolParams.protocol, 'SquintToPulse')
            MaxLMSPostFigure = figure;
            MaxLMSPostValidation = summarizeValidation(MaxLMSDirection, 'whichValidationPrefix', 'postcorrection', 'plot', 'off');
            MaxLMSPassStatus = applyValidationExclusionCriteria(MaxLMSPostValidation, MaxLMSDirection);
            MaxLMSPostValidation = summarizeValidation(MaxLMSDirection);
        elseif strcmp(protocolParams.protocol, 'Deuteranopes')
            fprintf('\n<strong>For L+S stimuli:</strong>\n');
            fprintf('\tL Cone Contrast: %4.2f %%\n',  MaxLMSDirection.describe.validation.contrastActual(1,1)*100);
            fprintf('\tS Cone Contrast: %4.2f %%\n',  MaxLMSDirection.describe.validation.contrastActual(3,1)*100);
            fprintf('\tMelanopsin Contrast: %4.2f %%\n',  MaxLMSDirection.describe.validation.contrastActual(4,1)*100);
        end
        
        %end
    end
    
    if strcmp(protocolParams.protocol, 'SquintToPulse') || strcmp(protocolParams.protocol, 'Screening') || strcmp(protocolParams.protocol, 'Deuteranopes')
        
        %if LightFluxPassStatus == 0
        OLCorrectDirection(LightFluxBackground, nullDirection, ol, radiometer, ...
            'smoothness', 0.1, ...
            'temperatureProbe', theLJdev, ...
            'lightlevelScalar',lightlevelScalar,...
            'measureStateTrackingSPDs', measureStateTrackingSPDs);
        OLCorrectDirection(LightFluxDirection, LightFluxBackground, ol, radiometer, ...
            'smoothness', 0.1, ...
            'temperatureProbe', theLJdev, ...
            'lightlevelScalar',lightlevelScalar,...
            'measureStateTrackingSPDs', measureStateTrackingSPDs);
        for ii = length(LightFluxDirection.describe.validation)+1:length(LightFluxDirection.describe.validation)+protocolParams.nValidationsPerDirection
            OLValidateDirection(LightFluxDirection, LightFluxBackground, ol, radiometer, ...
                'receptors', T_receptors, 'label', 'postcorrection', ...
                'temperatureProbe', theLJdev, ...
                'measureStateTrackingSPDs', measureStateTrackingSPDs);
            postreceptoralContrast = ComputePostreceptoralContrastsFromLMSContrasts(LightFluxDirection.describe.validation(ii).contrastActual(1:3,1));
            LightFluxDirection.describe.validation(ii).postreceptoralContrastActual = postreceptoralContrast;
            save(fullfile(savePath, 'LightFluxBackground.mat'), 'LightFluxBackground');
            save(fullfile(savePath, 'LightFluxDirection.mat'), 'LightFluxDirection');
        end
        if strcmp(protocolParams.protocol, 'SquintToPulse') || strcmp(protocolParams.protocol, 'Screening')
            LightFluxPostFigure = figure;
            LightFluxPostValidationJustPost = summarizeValidation(LightFluxDirection, 'whichValidationPrefix', 'postcorrection', 'plot', 'off');
            LightFluxPassStatus = applyValidationExclusionCriteria(LightFluxPostValidationJustPost, LightFluxDirection);
            LightFluxPostValidation = summarizeValidation(LightFluxDirection);
        elseif strcmp(protocolParams.protocol, 'Deuteranopes')
            fprintf('\n<strong>For LightFlux stimuli:</strong>\n');
            fprintf('\tL Cone Contrast: %4.2f %%\n',  LightFluxDirection.describe.validation.contrastActual(1,1)*100);
            fprintf('\tS Cone Contrast: %4.2f %%\n',  LightFluxDirection.describe.validation.contrastActual(3,1)*100);
            fprintf('\tMelanopsin Contrast: %4.2f %%\n',  LightFluxDirection.describe.validation.contrastActual(4,1)*100);
        end
        
        %end
        
    end
end

%% Check if we have god modulations

% for SquintToPulse protocol
if strcmp(protocolParams.protocol, 'SquintToPulse')
    
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
    
    lightFluxBackgroundLuminancePreExperiment = median(LightFluxPostValidationJustPost.backgroundLuminance);
    
    if lightFluxBackgroundLuminancePreExperiment > 254.6685
        backgroundLuminance = 0;
        fprintf('<strong>Background luminance for lightflux stimuli is %.2f, which is too bright</strong>\n', lightFluxBackgroundLuminancePreExperiment);
    elseif lightFluxBackgroundLuminancePreExperiment < 160.685
        backgroundLuminance = 0;
        fprintf('<strong>Background luminance for lightflux stimuli is %.2f, which is too dim</strong>\n', lightFluxBackgroundLuminancePreExperiment);
    else
        backgroundLuminance = 1;
        fprintf('Background luminance for lightflux stimuli is %.2f\n', lightFluxBackgroundLuminancePreExperiment);
    end
    
    if MaxMelPassStatus == 1 && MaxLMSPassStatus == 1 && LightFluxPassStatus == 1 && backgroundLuminance == 1
        fprintf('***We have good modulations and are ready for the experiment***\n');
    else
        fprintf('<strong>***Modulations are poor, we have to figure something out***</strong>\n');
    end
end

% for screening protocol
if strcmp(protocolParams.protocol, 'Screening')
    if LightFluxPassStatus == 1
        fprintf('Light flux modulations are good\n');
    else
        fprintf('<strong>Light flux  modulations are poor</strong>\n');
    end
end

% NEED SOMETHING FOR DEUTERANOPES HERE. MAINLY JUST A REMINDER TO FIGURE
% OUT SPLATTER FOR DEUTS


%% save directions and backgrounds


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


%% Make waveform
if strcmp(protocolParams.protocol, 'SquintToPulse') || strcmp(protocolParams.protocol, 'Screening')
    waveformParams = OLWaveformParamsFromName('MaxContrastPulse'); % get generic pulse parameters
    waveformParams.stimulusDuration = 4; % 4 second pulses
    [Pulse400Waveform, pulseTimestep] = OLWaveformFromParams(waveformParams); % 4 second pulse waveform max contrast
    Pulse200Waveform = Pulse400Waveform / 2;
    Pulse100Waveform = Pulse400Waveform / 4;
elseif strcmp(protocolParams.protocol, 'Deuteranopes')
    waveformParams = OLWaveformParamsFromName('MaxContrastPulse'); % get generic pulse parameters
    waveformParams.stimulusDuration = 4; % 4 second pulses
    [Pulse1200Waveform, pulseTimestep] = OLWaveformFromParams(waveformParams); % 4 second pulse waveform max contrast
    Pulse800Waveform = Pulse1200Waveform * (2/3);
    Pulse400Waveform = Pulse1200Waveform * (1/3);
end

%% Make the modulation starts and stops

if strcmp(protocolParams.protocol, 'SquintToPulse')
    
    Mel400PulseModulation = OLAssembleModulation([MaxMelBackground, MaxMelDirection], [ones(1, length(Pulse400Waveform)); Pulse400Waveform]);
    Mel200PulseModulation = OLAssembleModulation([MaxMelBackground, MaxMelDirection], [ones(1, length(Pulse200Waveform)); Pulse200Waveform]);
    Mel100PulseModulation = OLAssembleModulation([MaxMelBackground, MaxMelDirection], [ones(1, length(Pulse100Waveform)); Pulse100Waveform]);
end

if strcmp(protocolParams.protocol, 'SquintToPulse')
    LMS400PulseModulation = OLAssembleModulation([MaxLMSBackground, MaxLMSDirection], [ones(1, length(Pulse400Waveform)); Pulse400Waveform]);
    LMS200PulseModulation = OLAssembleModulation([MaxLMSBackground, MaxLMSDirection], [ones(1, length(Pulse200Waveform)); Pulse200Waveform]);
    LMS100PulseModulation = OLAssembleModulation([MaxLMSBackground, MaxLMSDirection], [ones(1, length(Pulse100Waveform)); Pulse100Waveform]);
end

if strcmp(protocolParams.protocol, 'SquintToPulse') || strcmp(protocolParams.protocol, 'Screening')
    
    LightFlux400PulseModulation = OLAssembleModulation([LightFluxBackground, LightFluxDirection], [ones(1, length(Pulse400Waveform)); Pulse400Waveform]);
    LightFlux200PulseModulation = OLAssembleModulation([LightFluxBackground, LightFluxDirection], [ones(1, length(Pulse200Waveform)); Pulse200Waveform]);
    LightFlux100PulseModulation = OLAssembleModulation([LightFluxBackground, LightFluxDirection], [ones(1, length(Pulse100Waveform)); Pulse100Waveform]);
end


if strcmp(protocolParams.protocol, 'Deuteranopes')
    Mel1200PulseModulation = OLAssembleModulation([MaxMelBackground, MaxMelDirection], [ones(1, length(Pulse1200Waveform)); Pulse1200Waveform]);
    Mel800PulseModulation = OLAssembleModulation([MaxMelBackground, MaxMelDirection], [ones(1, length(Pulse800Waveform)); Pulse800Waveform]);
    Mel400PulseModulation = OLAssembleModulation([MaxMelBackground, MaxMelDirection], [ones(1, length(Pulse400Waveform)); Pulse400Waveform]);
    
    LMS1200PulseModulation = OLAssembleModulation([MaxLMSBackground, MaxLMSDirection], [ones(1, length(Pulse1200Waveform)); Pulse1200Waveform]);
    LMS800PulseModulation = OLAssembleModulation([MaxLMSBackground, MaxLMSDirection], [ones(1, length(Pulse800Waveform)); Pulse800Waveform]);
    LMS400PulseModulation = OLAssembleModulation([MaxLMSBackground, MaxLMSDirection], [ones(1, length(Pulse400Waveform)); Pulse400Waveform]);
    
    LightFlux1200PulseModulation = OLAssembleModulation([LightFluxBackground, LightFluxDirection], [ones(1, length(Pulse1200Waveform)); Pulse1200Waveform]);
    LightFlux800PulseModulation = OLAssembleModulation([LightFluxBackground, LightFluxDirection], [ones(1, length(Pulse800Waveform)); Pulse800Waveform]);
    LightFlux400PulseModulation = OLAssembleModulation([LightFluxBackground, LightFluxDirection], [ones(1, length(Pulse400Waveform)); Pulse400Waveform]);
    
end
%% Define all modulations

if strcmp(protocolParams.protocol, 'SquintToPulse')
    
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
end

if strcmp(protocolParams.protocol, 'SquintToPulse')
    
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
end

if strcmp(protocolParams.protocol, 'SquintToPulse') || strcmp(protocolParams.protocol, 'Screening')
    
    % LightFlux Modulations
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
end

if strcmp(protocolParams.protocol, 'Deuteranopes')
    
    % Mel modulations
    Mel1200PulseModulationData.modulationParams.direction = "Melanopsin 1200% contrast";
    Mel1200PulseModulationData.modulation = Mel1200PulseModulation;
    [Mel1200PulseModulationData.modulation.background.starts, Mel1200PulseModulationData.modulation.background.stops] = OLPrimaryToStartsStops(MaxMelBackground.differentialPrimaryValues, calibration);
    Mel1200PulseModulationData.modulationParams.stimulusDuration = waveformParams.stimulusDuration;
    Mel1200PulseModulationData.modulationParams.timeStep = pulseTimestep;
    
    Mel800PulseModulationData.modulationParams.direction = "Melanopsin 800% contrast";
    Mel800PulseModulationData.modulation = Mel800PulseModulation;
    [Mel800PulseModulationData.modulation.background.starts, Mel800PulseModulationData.modulation.background.stops] = OLPrimaryToStartsStops(MaxMelBackground.differentialPrimaryValues, calibration);
    Mel800PulseModulationData.modulationParams.stimulusDuration = waveformParams.stimulusDuration;
    Mel800PulseModulationData.modulationParams.timeStep = pulseTimestep;
    
    Mel400PulseModulationData.modulationParams.direction = "Melanopsin 400% contrast";
    Mel400PulseModulationData.modulation = Mel400PulseModulation;
    [Mel400PulseModulationData.modulation.background.starts, Mel400PulseModulationData.modulation.background.stops] = OLPrimaryToStartsStops(MaxMelBackground.differentialPrimaryValues, calibration);
    Mel400PulseModulationData.modulationParams.stimulusDuration = waveformParams.stimulusDuration;
    Mel400PulseModulationData.modulationParams.timeStep = pulseTimestep;
    
    % LMS modulations
    LMS1200PulseModulationData.modulationParams.direction = "L+S 1200% contrast";
    LMS1200PulseModulationData.modulation = LMS1200PulseModulation;
    [LMS1200PulseModulationData.modulation.background.starts, LMS1200PulseModulationData.modulation.background.stops] = OLPrimaryToStartsStops(MaxLMSBackground.differentialPrimaryValues, calibration);
    LMS1200PulseModulationData.modulationParams.stimulusDuration = waveformParams.stimulusDuration;
    LMS1200PulseModulationData.modulationParams.timeStep = pulseTimestep;
    
    LMS800PulseModulationData.modulationParams.direction = "L+S 800% contrast";
    LMS800PulseModulationData.modulation = LMS800PulseModulation;
    [LMS800PulseModulationData.modulation.background.starts, LMS800PulseModulationData.modulation.background.stops] = OLPrimaryToStartsStops(MaxLMSBackground.differentialPrimaryValues, calibration);
    LMS800PulseModulationData.modulationParams.stimulusDuration = waveformParams.stimulusDuration;
    LMS800PulseModulationData.modulationParams.timeStep = pulseTimestep;
    
    LMS400PulseModulationData.modulationParams.direction = "L+S 400% contrast";
    LMS400PulseModulationData.modulation = LMS400PulseModulation;
    [LMS400PulseModulationData.modulation.background.starts, LMS400PulseModulationData.modulation.background.stops] = OLPrimaryToStartsStops(MaxLMSBackground.differentialPrimaryValues, calibration);
    LMS400PulseModulationData.modulationParams.stimulusDuration = waveformParams.stimulusDuration;
    LMS400PulseModulationData.modulationParams.timeStep = pulseTimestep;
    
    % LightFlux modulations
    LightFlux1200PulseModulationData.modulationParams.direction = "LightFlux 1200% contrast";
    LightFlux1200PulseModulationData.modulation = LightFlux1200PulseModulation;
    [LightFlux1200PulseModulationData.modulation.background.starts, LightFlux1200PulseModulationData.modulation.background.stops] = OLPrimaryToStartsStops(LightFluxBackground.differentialPrimaryValues, calibration);
    LightFlux1200PulseModulationData.modulationParams.stimulusDuration = waveformParams.stimulusDuration;
    LightFlux1200PulseModulationData.modulationParams.timeStep = pulseTimestep;
    
    LightFlux800PulseModulationData.modulationParams.direction = "LightFlux 800% contrast";
    LightFlux800PulseModulationData.modulation = LightFlux800PulseModulation;
    [LightFlux800PulseModulationData.modulation.background.starts, LightFlux800PulseModulationData.modulation.background.stops] = OLPrimaryToStartsStops(LightFluxBackground.differentialPrimaryValues, calibration);
    LightFlux800PulseModulationData.modulationParams.stimulusDuration = waveformParams.stimulusDuration;
    LightFlux800PulseModulationData.modulationParams.timeStep = pulseTimestep;
    
    LightFlux400PulseModulationData.modulationParams.direction = "LightFlux 400% contrast";
    LightFlux400PulseModulationData.modulation = LightFlux400PulseModulation;
    [LightFlux400PulseModulationData.modulation.background.starts, LightFlux400PulseModulationData.modulation.background.stops] = OLPrimaryToStartsStops(LightFluxBackground.differentialPrimaryValues, calibration);
    LightFlux400PulseModulationData.modulationParams.stimulusDuration = waveformParams.stimulusDuration;
    LightFlux400PulseModulationData.modulationParams.timeStep = pulseTimestep;
    
end

% save modulations
savePath = fullfile(getpref('OLApproach_Squint', 'DataPath'), 'Experiments', protocolParams.approach, protocolParams.protocol, 'ModulationStructs', protocolParams.observerID, [protocolParams.todayDate, '_', protocolParams.sessionName]);
if ~exist(savePath,'dir')
    mkdir(savePath);
end

if strcmp(protocolParams.protocol, 'SquintToPulse')
    
    save(fullfile(savePath, 'Mel400PulseModulationData.mat'), 'Mel400PulseModulationData');
    save(fullfile(savePath, 'Mel200PulseModulationData.mat'), 'Mel200PulseModulationData');
    save(fullfile(savePath, 'Mel100PulseModulationData.mat'), 'Mel100PulseModulationData');
end

if strcmp(protocolParams.protocol, 'SquintToPulse')
    save(fullfile(savePath, 'LMS400PulseModulationData.mat'), 'LMS400PulseModulationData');
    save(fullfile(savePath, 'LMS200PulseModulationData.mat'), 'LMS200PulseModulationData');
    save(fullfile(savePath, 'LMS100PulseModulationData.mat'), 'LMS100PulseModulationData');
end

if strcmp(protocolParams.protocol, 'SquintToPulse') || strcmp(protocolParams.protocol, 'Screening')
    
    save(fullfile(savePath, 'LightFlux400PulseModulationData.mat'), 'LightFlux400PulseModulationData');
    save(fullfile(savePath, 'LightFlux200PulseModulationData.mat'), 'LightFlux200PulseModulationData');
    save(fullfile(savePath, 'LightFlux100PulseModulationData.mat'), 'LightFlux100PulseModulationData');
end

if strcmp(protocolParams.protocol, 'Deuteranopes')
    
    save(fullfile(savePath, 'Mel1200PulseModulationData.mat'), 'Mel200PulseModulationData');
    save(fullfile(savePath, 'Mel800PulseModulationData.mat'), 'Mel800PulseModulationData');
    save(fullfile(savePath, 'Mel400PulseModulationData.mat'), 'Mel400PulseModulationData');
    
    save(fullfile(savePath, 'LMS1200PulseModulationData.mat'), 'LMS200PulseModulationData');
    save(fullfile(savePath, 'LMS800PulseModulationData.mat'), 'LMS800PulseModulationData');
    save(fullfile(savePath, 'LMS400PulseModulationData.mat'), 'LMS400PulseModulationData');
    
    save(fullfile(savePath, 'LightFlux1200PulseModulationData.mat'), 'LightFlux200PulseModulationData');
    save(fullfile(savePath, 'LightFlux800PulseModulationData.mat'), 'LightFlux800PulseModulationData');
    save(fullfile(savePath, 'LightFlux400PulseModulationData.mat'), 'LightFlux400PulseModulationData');
    
end

%% Package up the output
if strcmp(protocolParams.protocol, 'SquintToPulse')
    
    modulationData = [Mel400PulseModulationData; Mel200PulseModulationData; Mel100PulseModulationData; ...
        LMS400PulseModulationData; LMS200PulseModulationData; LMS100PulseModulationData; ...
        LightFlux400PulseModulationData; LightFlux200PulseModulationData; LightFlux100PulseModulationData];
end

if strcmp(protocolParams.protocol, 'Screening')
    modulationData = [LightFlux400PulseModulationData; LightFlux200PulseModulationData; LightFlux100PulseModulationData];
end

if strcmp(protocolParams.protocol, 'Deuteranopes')

        modulationData = [Mel1200PulseModulationData; Mel800PulseModulationData; Mel400PulseModulationData; ...
        LMS1200PulseModulationData; LMS800PulseModulationData; LMS400PulseModulationData; ...
        LightFlux1200PulseModulationData; LightFlux800PulseModulationData; LightFlux400PulseModulationData];
end

%% Shutdown the LabJack object
if (takeTemperatureMeasurements)
    % Close temperature probe
    theLJdev.close();
end

end % end function

