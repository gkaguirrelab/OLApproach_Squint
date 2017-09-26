function OLApproach_SquintLocalHook
% OLApproach_PsychophysicsLocalHook - Configure things for working on OneLight projects.
%
% For use with the ToolboxToolbox.  If you copy this into your
% ToolboxToolbox localToolboxHooks directory (by default,
% ~/localToolboxHooks) and delete "LocalHooksTemplate" from the filename,
% this will get run when you execute
%   tbUseProject('OLApproach_PsychophysicsLocalHook')
% to set up for this project.  You then edit your local copy to match your local machine.
%
% The main thing that this does is define Matlab preferences that specify input and output
% directories.
%
% You will need to edit the project location and i/o directory locations
% to match what is true on your computer.

%% Say hello
fprintf('Running OLApproach_Squint local hook\n');
theApproach = 'OLApproach_Squint';

%% Define protocols for this approach
theProtocols = { ...
    'SquintToPulse' ...
    };

%% Remove old preferences
if (ispref(theApproach))
    rmpref(theApproach);
end
for pp = 1:length(theProtocols)
    if (ispref(theProtocols{pp}))
        rmpref(theProtocols{pp});
    end
end

%% Specify base paths for materials and data
[~, userID] = system('whoami');
userID = strtrim(userID);
switch userID
    case {'melanopsin' 'pupillab'}
        materialsBasePath = ['/Users/' userID '/Dropbox (Aguirre-Brainard Lab)/MELA_materials'];
        dataBasePath = ['/Users/' userID '/Dropbox (Aguirre-Brainard Lab)/MELA_data/'];
    case {'dhb'}
        materialsBasePath = ['/Users1'  '/Dropbox (Aguirre-Brainard Lab)/MELA_materials'];
        dataBasePath = ['/Users1' '/Dropbox (Aguirre-Brainard Lab)/MELA_data/'];     
    case {'nicolas'}
        materialsBasePath = '/Volumes/Manta TM HD/Dropbox (Aguirre-Brainard Lab)/MELA_materials';
        dataBasePath = '/Volumes/Manta TM HD/Dropbox (Aguirre-Brainard Lab)/MELA_data';
    otherwise
        materialsBasePath = ['/Users/' userID '/Dropbox (Aguirre-Brainard Lab)/MELA_materials'];
        dataBasePath = ['/Users/' userID '/Dropbox (Aguirre-Brainard Lab)/MELA_data/'];
end

%% Set prefs for materials and data
setpref(theApproach,'MaterialsPath',fullfile(materialsBasePath));
setpref(theApproach,'DataPath',fullfile(dataBasePath));
   
%% Set pref to point at the code for this approach
setpref(theApproach,'CodePath', fullfile(tbLocateProject(theApproach),'code'));

%% Set the calibration file path
setpref(theApproach, 'OneLightCalDataPath', fullfile(getpref(theApproach, 'MaterialsPath'), 'Experiments', theApproach, 'OneLightCalData'));
setpref('OneLightToolbox','OneLightCalData',getpref(theApproach,'OneLightCalDataPath'));

%% Set the background nominal primaries path
setpref(theApproach,'BackgroundNominalPrimariesPath',fullfile(getpref(theApproach, 'MaterialsPath'),'Experiments',theApproach,'BackgroundNominalPrimaries'));

%% Set the direction nominal primaries path
setpref(theApproach,'DirectionNominalPrimariesPath',fullfile(getpref(theApproach, 'MaterialsPath'),'Experiments',theApproach,'DirectionNominalPrimaries'));

%% Prefs for individual protocols
for pp = 1:length(theProtocols)
    setpref(theProtocols{pp},'DirectionCorrectedPrimariesBasePath',fullfile(getpref(theApproach, 'DataPath'),'Experiments',theApproach,theProtocols{pp},'DirectionCorrectedPrimaries'));
    
    % Set the validation base path
    setpref(theProtocols{pp},'DirectionCorrectedValidationBasePath',fullfile(getpref(theApproach, 'DataPath'),'Experiments',theApproach,theProtocols{pp},'DirectionValidationFiles'));
    
    % Modulation starts/stops files base path
    setpref(theProtocols{pp},'ModulationStartsStopsBasePath',fullfile(getpref(theApproach, 'DataPath'),'Experiments',theApproach,theProtocols{pp},'ModulationsStartsStops'));
    
    % Session record base path
    setpref(theProtocols{pp},'SessionRecordsBasePath',fullfile(getpref(theApproach, 'DataPath'),'Experiments',theApproach,theProtocols{pp},'SessionRecords'));
    
    % Data files base path
    setpref(theProtocols{pp},'DataFilesBasePath',fullfile(getpref(theApproach, 'DataPath'),'Experiments',theApproach,theProtocols{pp},'DataFiles'));
end

%% Set the default speak rate
setpref(theApproach, 'SpeakRateDefault', 230);

%% Add OmniDriver.jar to java path
OneLightDriverPath = tbLocateToolbox('OneLightDriver');
JavaAddToPath(fullfile(OneLightDriverPath,'xOceanOpticsJava/OmniDriver.jar'),'OmniDriver.jar');
