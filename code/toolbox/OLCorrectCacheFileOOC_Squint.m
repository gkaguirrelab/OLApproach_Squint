function [cacheData] = OLCorrectCacheFileOOC_Squint(cacheData, cal, ol, spectroRadiometerOBJ, varargin)
% results = OLCorrectCacheFileOOC(cacheFileName, emailRecipient, ...
%    meterType, spectroRadiometerOBJ, spectroRadiometerOBJWillShutdownAfterMeasurement, varargin)
%
% OLCorrectCacheFileOOC - Use iterated procedure to optimize modulations in a cache file
%
% Syntax:
% OLValidateCacheFile(cacheFileName)
%
% Description:
% Uses an iterated procedure to bring a modulation as close as possible to
% its specified spectrum.
%
% Input:
% cacheFileName (string)    - The name of the cache file to validate.  The
%                             file name must be an absolute path.  This is
%                             because relative path can match anything on the
%                             Matlab path, which could lead to unintended
%                             results.
% emailRecipient (string)   - Email address to receive notifications
% meterType (string)        - Meter type to use.
% spectroRadiometerOBJ      - A previously open PR650 or PR670 object
% spectroRadiometerOBJWillShutdownAfterMeasurement - Boolean, indicating
%                             whether to shutdown the radiometer object
% varargin (keyword-value)  - A few keywords which determine the behavior
%                             of the routine.
%                             Keyword               Default   Behavior
%                             'ReferenceMode'       true      Adds suffix
%                                                             to file name
%                             'FullOnMeas'          true      Full-on
%                             'HalfOnMeas'          false     Half-on
%                             'CalStateMeas'        true      State measurements
%                             'SkipBackground'      false     Background
%                             'ReducedPowerLevels'  true      Only 3 levels
%                             'NoAdjustment      '  true      Does not pause
%                             'OBSERVER_AGE' 32     Standard obs.
%                             'selectedCalType'     'EyeTrackerLongCableEyePiece1' Calibration type
%                             'powerLevels'         scalar    Which power levels
%                             'NIter'               scalar    number of iterations
%                             'lambda'              scalar    Learning rate
%                             'postreceptoralCombinations'  scalar Post-receptoral combinations to calculate contrast w.r.t.
%                             'takeTemperatureMeasurements' false  Whether to take temperature measurements (requires a
%                                                                  connected LabJack dev with a temperature probe)
% Output:
% results (struct) - Results struct. This is different depending on which mode is used.
% validationDir (str) - Validation directory.

% 1/21/14   dhb, ms  Convert to use OLSettingsToStartsStops.
% 1/30/14   ms       Added keyword parameters to make this useful.
% 7/06/16   npc      Adapted to use PR650dev/PR670dev objects
% 10/20/16  npc      Added ability to record temperature measurements
% 12/21/16  npc      Updated for new class @LJTemperatureProbe

% Parse the input
p = inputParser;
p.addOptional('ReferenceMode', true, @islogical);
p.addOptional('FullOnMeas', true, @islogical);
p.addOptional('HalfOnMeas', false, @islogical);
p.addOptional('DarkMeas', false, @islogical);
p.addOptional('CalStateMeas', false, @islogical);
p.addOptional('SkipBackground', false, @islogical);
p.addOptional('ReducedPowerLevels', true, @islogical);
p.addOptional('NoAdjustment', false, @islogical);
p.addOptional('OBSERVER_AGE', 32, @isscalar);
p.addOptional('NIter', 20, @isscalar);
p.addOptional('lambda', 0.8, @isscalar);
p.addOptional('selectedCalType', [], @isstr);
p.addOptional('CALCULATE_SPLATTER', true, @islogical);
p.addOptional('powerLevels', 32, @isnumeric);
p.addOptional('doCorrection', true, @islogical);
p.addOptional('postreceptoralCombinations', [], @isnumeric);
p.addOptional('outDir', [], @isstr);
p.addOptional('takeTemperatureMeasurements', false, @islogical);
p.parse(varargin{:});
describe = p.Results;
powerLevels = describe.powerLevels;
takeTemperatureMeasurements = describe.takeTemperatureMeasurements;


% All variables assigned in the following if (isempty(..)) block (except
% spectroRadiometerOBJ) must be declared as persistent
persistent S
persistent nAverage
persistent theMeterTypeID
% 
% if (isempty(spectroRadiometerOBJ))
%     % Open up the radiometer if this is the first cache file we validate
%     try
%         switch (meterType)
%             case 'PR-650',
%                 theMeterTypeID = 1;
%                 S = [380 4 101];
%                 nAverage = 1;
%                 
%                 % Instantiate a PR650 object
%                 spectroRadiometerOBJ  = PR650dev(...
%                     'verbosity',        1, ...       % 1 -> minimum verbosity
%                     'devicePortString', [] ...       % empty -> automatic port detection)
%                     );
%                 spectroRadiometerOBJ.setOptions('syncMode', 'OFF');
%                 
%             case 'PR-670',
%                 theMeterTypeID = 5;
%                 S = [380 2 201];
%                 nAverage = 1;
%                 
%                 % Instantiate a PR670 object
%                 spectroRadiometerOBJ  = PR670dev(...
%                     'verbosity',        1, ...       % 1 -> minimum verbosity
%                     'devicePortString', [] ...       % empty -> automatic port detection)
%                     );
%                 
%                 % Set options Options available for PR670:
%                 spectroRadiometerOBJ.setOptions(...
%                     'verbosity',        1, ...
%                     'syncMode',         'OFF', ...      % choose from 'OFF', 'AUTO', [20 400];
%                     'cyclesToAverage',  1, ...          % choose any integer in range [1 99]
%                     'sensitivityMode',  'STANDARD', ... % choose between 'STANDARD' and 'EXTENDED'.  'STANDARD': (exposure range: 6 - 6,000 msec, 'EXTENDED': exposure range: 6 - 30,000 msec
%                     'exposureTime',     'ADAPTIVE', ... % choose between 'ADAPTIVE' (for adaptive exposure), or a value in the range [6 6000] for 'STANDARD' sensitivity mode, or a value in the range [6 30000] for the 'EXTENDED' sensitivity mode
%                     'apertureSize',     '1 DEG' ...     % choose between '1 DEG', '1/2 DEG', '1/4 DEG', '1/8 DEG'
%                     );
%             otherwise,
%                 error('Unknown meter type');
%         end
%         
%     catch err
%         if (~isempty(spectroRadiometerOBJ))
%             spectroRadiometerOBJ.shutDown();
%             openSpectroRadiometerOBJ = [];
%         end
%         SendEmail(emailRecipient, 'OLValidateCacheFileOOC Failed', ...
%             ['Calibration failed with the following error' 10 err.message]);
%         keyboard;
%         rethrow(err);
%     end
%     
%     
% end
openSpectroRadiometerOBJ = spectroRadiometerOBJ;

% Attempt to open the LabJack temperature sensing device
if (takeTemperatureMeasurements)
    % Gracefully attempt to open the LabJack
    [takeTemperatureMeasurements, quitNow, theLJdev] = OLCalibrator.OpenLabJackTemperatureProbe(takeTemperatureMeasurements);
    if (quitNow)
        return;
     end
else
     theLJdev = [];
end

% % Force the file to be an absolute path instead of a relative one.  We do
% % this because files with relative paths can match anything on the path,
% % which may not be what was intended.  The regular expression looks for
% % string that begins with '/' or './'.
% m = regexp(cacheFileName, '^(\.\/|\/).*', 'once');
% assert(~isempty(m), 'OLValidateCacheFile:InvalidPathDef', ...
%     'Cache file name must be an absolute path.');
% 
% % Make sure the file exists.
% assert(logical(exist(cacheFileName, 'file')), 'OLValidateCacheFile:FileNotFound', ...
%     'Cannot find cache file: %s', cacheFileName);
% 
% % Deduce the cache directory and load the cache file
% cacheDir = fileparts(cacheFileName);
% data = load(cacheFileName);
% assert(isstruct(data), 'OLValidateCacheFile:InvalidCacheFile', ...
%     'Specified file doesn''t seem to be a cache file: %s', cacheFileName);
% 
% % List the available calibration types found in the cache file.
% foundCalTypes = sort(fieldnames(data));
% 
% % Make sure the all the calibration types loaded seem legit. We want to
% % make sure that we have at least one calibration type which we know of.
% % Otherwise, we abort.
% [~, validCalTypes] = enumeration('OLCalibrationTypes');
% for i = 1:length(foundCalTypes)
%     typeExists(i) = any(strcmp(foundCalTypes{i}, validCalTypes));
% end
% assert(any(typeExists), 'OLValidateCacheFile:InvalidCacheFile', ...
%     'File contains does not contain at least one valid calibration type');
% 
% % Display a list of all the calibration types contained in the file and
% % have the user select one to validate.
% while true
%     fprintf('\n- Calibration Types in Cache File (*** = valid)\n\n');
%     
%     for i = 1:length(foundCalTypes)
%         if typeExists(i)
%             typeState = '***';
%         else
%             typeState = '---';
%         end
%         fprintf('%i (%s): %s\n', i, typeState, foundCalTypes{i});
%     end
%     fprintf('\n');
%     
%     % Check if 'selectedCalType' was passed.
%     if (isfield(describe, 'selectedCalType')) && any(strcmp(foundCalTypes, describe.selectedCalType))
%         selectedCalType = describe.selectedCalType;
%         break;
%     end
%     
%     t = GetInput('Select a Number', 'number', 1);
%     
%     if t >= 1 && t <= length(foundCalTypes) && typeExists(t);
%         fprintf('\n');
%         selectedCalType = foundCalTypes{t};
%         break;
%     else
%         fprintf('\n*** Invalid selection try again***\n\n');
%     end
% end
% 
% % Load the calibration file associated with this calibration type.
% cal = LoadCalFile(OLCalibrationTypes.(selectedCalType).CalFileName, [], fullfile('/Users/melanopsin/Dropbox (Aguirre-Brainard Lab)/MELA_materials/Legacy/OneLightCalData'));
% 
% % Pull out the file name
% cacheFileNameFull = cacheFileName;
% [~, cacheFileName] = fileparts(cacheFileName);
% 
% %% Determine which meters to measure with
% %
% % It is probably a safe assumption that we will not validate a cache file
% % with the Omni with respect to a calibration that was done without the
% % Omni. Therefore, we read out the toggle directly from the calibration
% % file. First entry is PR-6xx and is always true. Second entry is omni and
% % can be on or off, depending on content of calibration.
meterToggle = [1 cal.describe.useOmni];
% 
% % Setup the OLCache object.
% olCache = OLCache(cacheDir, cal);
% 
% % Load the calibration data.  We do it through the cache object so that we
% % make sure that the cache is current against the latest calibration data.
% [~, simpleCacheFileName] = fileparts(cacheFileName);
% [cacheData, wasRecomputed] = olCache.load(simpleCacheFileName);
% 
% % If we recomputed the cache data, save it.  We'll load the cache data
% % after we save it because cache data is uniquely time stamped upon save.
% if wasRecomputed
%     olCache.save(simpleCacheFileName, cacheData);
%     cacheData = olCache.load(simpleCacheFileName);
% end

if ~(describe.doCorrection)
   return; % Just return with no correction 
end

% Connect to the OceanOptics spectrometer.
if (cal.describe.useOmni)
    od = OmniDriver;
    od.Debug = true;
    % Turn on some averaging and smoothing for the spectrum acquisition.
    od.ScansToAverage = 10;
    od.BoxcarWidth = 2;
    
    % Make sure electrical dark correction is enabled.
    od.CorrectForElectricalDark = true;
    
    % Set the OmniDriver integration time to match up with what's in the
    % calibration file.
    od.IntegrationTime = cal.describe.omniDriver.integrationTime;
else
    od = [];
end

% Open up the OneLight
%ol = OneLight;

% Turn the mirrors full on so the user can focus the radiometer.
if describe.NoAdjustment
    ol.setAll(true);
    pauseDuration = 0;
    fprintf('- Focus the radiometer and press enter to pause %d seconds and start measuring.\n', ...
        pauseDuration);
    input('');
    ol.setAll(false);
    pause(pauseDuration);
else
    ol.setAll(false);
end

try
    startMeas = GetSecs;
    fprintf('- Performing radiometer measurements.\n');
    
    % Take reference measurements
    if describe.FullOnMeas
        fprintf('- Full-on measurement \n');
        [starts,stops] = OLSettingsToStartsStops(cal,1*ones(cal.describe.numWavelengthBands, 1));
        results.fullOnMeas.meas = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, S, meterToggle, nAverage);
        results.fullOnMeas.starts = starts;
        results.fullOnMeas.stops = stops;
        results.fullOnMeas.predictedFromCal = cal.raw.fullOn(:, 1);
        if (takeTemperatureMeasurements)
            printf('Taking temperature for fullOnMeas\n');
            [status, results.temperature.fullOnMeas] = theLJdev.measure();
        end
    end
    
    if describe.HalfOnMeas
        fprintf('- Half-on measurement \n');
        [starts,stops] = OLSettingsToStartsStops(cal,0.5*ones(cal.describe.numWavelengthBands, 1));
        results.halfOnMeas.meas = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, S, meterToggle, nAverage);
        results.halfOnMeas.starts = starts;
        results.halfOnMeas.stops = stops;
        results.halfOnMeas.predictedFromCal = cal.raw.halfOnMeas(:, 1);
        if (takeTemperatureMeasurements)
            [status, results.temperature.halfOnMeas] = theLJdev.measure();
        end 
    end
    
    if describe.DarkMeas
        fprintf('- Dark measurement \n');
        [starts,stops] = OLSettingsToStartsStops(cal,0*ones(cal.describe.numWavelengthBands, 1));
        results.offMeas.meas = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, S, meterToggle, nAverage);
        results.offMeas.starts = starts;
        results.offMeas.stops = stops;
        results.offMeas.predictedFromCal = cal.raw.darkMeas(:, 1);
        if (takeTemperatureMeasurements)
            [status, results.temperature.offMeas] = theLJdev.measure();
        end
    end
    
    if describe.CalStateMeas
        fprintf('- State measurements \n');
        [~, calStateMeas] = OLCalibrator.TakeStateMeasurements(cal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage, 'standAlone',true);
        OLCalibrator.SaveStateMeasurements(cal, calStateMeas);
    end
    
    % Loop over the stimuli in the cache file and take a measurement with the PR-670.
    iter = 1;
    switch cacheData.computeMethod
        case 'ReceptorIsolate'
            while iter <= describe.NIter
                % Set up the power levels to use.
                if describe.ReducedPowerLevels
                    % Only take three measurements
                    if describe.SkipBackground
                        nPowerLevels = 2
                        powerLevels = [-1 1];
                    else
                        if strcmp(cacheData.data(32).describe.params.receptorIsolateMode, 'PIPR')
                            nPowerLevels = 2;
                            powerLevels = [0 1];
                        else
                            nPowerLevels = 3;
                            powerLevels = [-1 0 1];
                        end
                    end
                else
                    % Take a full set of measurements
                    nPowerLevels = length(powerLevels);
                end
                
                % Only get the primaries from the cache file if it's the first iteration
                if iter == 1
                    backgroundPrimary = cacheData.data(describe.OBSERVER_AGE).backgroundPrimary;
                    differencePrimary = cacheData.data(describe.OBSERVER_AGE).differencePrimary;
                    modulationPrimary = cacheData.data(describe.OBSERVER_AGE).backgroundPrimary+cacheData.data(describe.OBSERVER_AGE).differencePrimary;
                else
                    backgroundPrimary = backgroundPrimaryCorrected;
                    modulationPrimary = modulationPrimaryCorrected;
                end
                
                % Refactor the cache data spectrum primaries to the power level.
                for i = 1:nPowerLevels
                    fprintf('- Measuring spectrum %d, level %g...\n', i, powerLevels(i));
                    if powerLevels(i) == 1
                        primaries = modulationPrimary;
                    elseif powerLevels(i) == 0
                        primaries = backgroundPrimary;
                    else
                        primaries = backgroundPrimary+powerLevels(i).*differencePrimary;
                    end
                    
                    % Convert the primaries to mirror settings.
                    settings = OLPrimaryToSettings(cal, primaries);
                    
                    % Compute the mirror starts and stops.
                    [starts,stops] = OLSettingsToStartsStops(cal, settings);
                    
                    % Take the measurements
                    results.modulationAllMeas(i).meas = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, S, meterToggle, nAverage);
                    
                    % Save out information about this.
                    results.modulationAllMeas(i).powerLevel = powerLevels(i);
                    results.modulationAllMeas(i).primaries = primaries;
                    results.modulationAllMeas(i).settings = settings;
                    results.modulationAllMeas(i).starts = starts;
                    results.modulationAllMeas(i).stops = stops;
                    if (takeTemperatureMeasurements)
                        [status, tempData] = theLJdev.measure();
                        results.temperature.modulationAllMeas(iter, i, :) = tempData;
                    end
                    
                    % If this is first time, figure out what spectrum we
                    % want, based on the stored primaries and the
                    % calibration data.  The stored primaries were
                    % generated so that they produced the desired spectrum
                    % when mapped through the calibration, so we just
                    % recrate that calculation here.
                    if iter == 1
                        results.modulationAllMeas(i).predictedSpd = OLPrimaryToSpd(cal,primaries);
                    end     
                end
                
                % For convenience we pull out the max, min and background.
                theMaxIndex = find([results.modulationAllMeas(:).powerLevel] == 1);
                theMinIndex = find([results.modulationAllMeas(:).powerLevel] == -1);
                theBGIndex = find([results.modulationAllMeas(:).powerLevel] == 0);
                if ~isempty(theMaxIndex)
                    results.modulationMaxMeas = results.modulationAllMeas(theMaxIndex);
                end
                
                % Sometimes there's no negative excursion. We set it to BG
                if ~isempty(theBGIndex)
                    results.modulationMinMeas = results.modulationAllMeas(theMinIndex);
                else 
                    results.modulationMinMeas = results.modulationAllMeas(theBGIndex);
                end
                
                % One of the measurements should have been the background,
                % pull that out so we have it handy.
                if ~isempty(theBGIndex)
                    results.modulationBGMeas = results.modulationAllMeas(theBGIndex);
                end
                
                % Determine the new primary settings from the measurements
                %
                % First, what spectrum did we measure?
                bgSpdAll(:,iter) = results.modulationBGMeas.meas.pr650.spectrum;
                modSpdAll(:,iter) = results.modulationMaxMeas.meas.pr650.spectrum;
                
                % Figure out a scaling factor from the first measurement
                % which puts the measured spectrum into the same range as
                % the predicted spectrum. This deals with fluctuations with
                % absolute light level.
                if iter == 1
                   kScale = results.modulationBGMeas.meas.pr650.spectrum \ results.modulationBGMeas.predictedSpd;
                end
                
                % Find out how much we missed by in primary space, by
                % taking the difference between the measured spectrum and
                % what we wanted to get.
                deltaBackgroundPrimaryInferred = OLSpdToPrimary(cal, (kScale*results.modulationBGMeas.meas.pr650.spectrum)-...
                    results.modulationBGMeas.predictedSpd, 'differentialMode', true);
                deltaModulationPrimaryInferred = OLSpdToPrimary(cal, (kScale*results.modulationMaxMeas.meas.pr650.spectrum)-...
                    results.modulationMaxMeas.predictedSpd, 'differentialMode', true);
                
                % Take a scaled version of the delta and subtract it from
                % the primaries we're trying, to get the new desired
                % primaries.
                backgroundPrimaryCorrected = backgroundPrimary - describe.lambda*deltaBackgroundPrimaryInferred;
                modulationPrimaryCorrected = modulationPrimary - describe.lambda*deltaModulationPrimaryInferred;
                
                % Make sure new primaries are between 0 and 1 by
                % truncating.
                backgroundPrimaryCorrected(backgroundPrimaryCorrected > 1) = 1;
                backgroundPrimaryCorrected(backgroundPrimaryCorrected < 0) = 0;
                modulationPrimaryCorrected(modulationPrimaryCorrected > 1) = 1;
                modulationPrimaryCorrected(modulationPrimaryCorrected < 0) = 0;
                
                theCanonicalPhotoreceptors = cacheData.data(describe.OBSERVER_AGE).describe.photoreceptors;
                T_receptors = cacheData.data(describe.OBSERVER_AGE).describe.T_receptors;
                
                % Save out information about the correction
                [contrasts(:,iter) postreceptoralContrasts(:,iter)] = ComputeAndReportContrastsFromSpds(['Iteration ' num2str(iter, '%02.0f')] ,theCanonicalPhotoreceptors,T_receptors,...
                    results.modulationBGMeas.meas.pr650.spectrum,results.modulationMaxMeas.meas.pr650.spectrum);
                
                backgroundPrimaryCorrectedAll(:,iter) = backgroundPrimaryCorrected;
                deltaBackgroundPrimaryInferredAll(:,iter)= deltaBackgroundPrimaryInferred;
                modulationPrimaryCorrectedAll(:,iter) = modulationPrimaryCorrected;
                deltaModulationPrimaryInferredAll(:,iter)= deltaModulationPrimaryInferred;
                
                % Increment
                iter = iter+1;
            end
    end
    
    % Replace the old nominal settings with the corrected ones.
    for ii = 1:length(cacheData.data)
        if ii == describe.OBSERVER_AGE;
            cacheData.data(ii).backgroundPrimary = backgroundPrimaryCorrectedAll(:, end);
            cacheData.data(ii).modulationPrimarySignedPositive = modulationPrimaryCorrectedAll(:, end);
            cacheData.data(ii).differencePrimary = modulationPrimaryCorrectedAll(:, end)-backgroundPrimaryCorrectedAll(:, end);
            cacheData.data(ii).correction.backgroundPrimaryCorrectedAll = backgroundPrimaryCorrectedAll;
            cacheData.data(ii).correction.deltaBackgroundPrimaryInferredAll = deltaBackgroundPrimaryInferredAll;
            cacheData.data(ii).correction.bgSpdAll = bgSpdAll;
            cacheData.data(ii).correction.modulationPrimaryCorrectedAll = modulationPrimaryCorrectedAll;
            cacheData.data(ii).correction.deltaModulationPrimaryInferredAll = deltaModulationPrimaryInferredAll;
            cacheData.data(ii).correction.modSpdAll = modSpdAll;
            cacheData.data(ii).correction.contrasts = contrasts;
            cacheData.data(ii).correction.postreceptoralContrasts = postreceptoralContrasts;
        else
            cacheData.data(ii).describe = [];
            cacheData.data(ii).backgroundPrimary = [];
            cacheData.data(ii).backgroundSpd = [];
            cacheData.data(ii).differencePrimary = [];
            cacheData.data(ii).differenceSpd = [];
            cacheData.data(ii).modulationPrimarySignedPositive = [];
            cacheData.data(ii).modulationPrimarySignedNegative = [];
            cacheData.data(ii).modulationSpdSignedPositive = [];
            cacheData.data(ii).modulationSpdSignedNegative = [];
            cacheData.data(ii).ambientSpd = [];
            cacheData.data(ii).operatingPoint = [];
            cacheData.data(ii).computeMethod = [];
        end
    end
    
    if (takeTemperatureMeasurements)  
        cacheData.temperatureData = results.temperature;
    end
    
    % Turn the OneLight mirrors off.
    ol.setAll(false);
    
    % Close the radiometer
    spectroRadiometerOBJWillShutdownAfterMeasurement = false;
    if (spectroRadiometerOBJWillShutdownAfterMeasurement)
        if (~isempty(spectroRadiometerOBJ))
            spectroRadiometerOBJ.shutDown();
            openSpectroRadiometerOBJ = [];
        end
    end
    
    % Check if we want to do splatter calculations
    try
        OLAnalyzeValidationReceptorIsolate(validationPath, 'short');
    end
    
% Something went wrong, try to close radiometer gracefully
catch e
    if (~isempty(spectroRadiometerOBJ))
        spectroRadiometerOBJ.shutDown();
        openSpectroRadiometerOBJ = [];
    end
    rethrow(e)
end