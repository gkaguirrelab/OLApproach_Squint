saveDir = fullfile(getpref('OLApproach_Squint', 'DataPath'), '../MELA_analysis/Experiments/OLApproach_Squint/Deuteranopes/admin');

% get calibration dates
calibrations = {};
[~, cals] = LoadCalFile('OLBoxALiquidShortCableDEyePiece1_ND02', [], getpref('OneLightToolbox', 'OneLightCalData'));
for ii = 1:length(cals)
    fullCalDate = strsplit(cals{ii}.describe.date, ' ');
    justDate = fullCalDate{1};
    [y, m, d] = ymd(datetime(justDate));
    calibrations{end+1} = [num2str(y), '-', sprintf('%02d', m),'-', num2str(d)];
end

firstDateToPlot = '2019-09-01';
excludedSessions.names = {};
excludedSessions.dates = {};
excludedSubjectNames = {'Harry'};

%% Experiment 1
experimentName = 'experiment_1';
saveDir = fullfile(getpref('OLApproach_Squint', 'DataPath'), '../MELA_analysis/Experiments/OLApproach_Squint/Deuteranopes/admin', experimentName);

% LS Modulations
% LS contrast
OLPlotValidationTimeSeries(...
'approachName', 'OLApproach_Squint', ...
'protocolName', 'Deuteranopes', ...
'objectType',   'DirectionObjects', ...
'objectName',   'MaxLMSDirection', ...
'visualizedProperty' , 'LSContrast', ...
'visualizedStatistics', 'medians and data points', ...
'experimentName', experimentName, ...
'excludedSubjectNames', excludedSubjectNames, ...
'yLim', [3.25 4.25], 'limits', [3.5 4.25], 'calibrations', calibrations, 'saveDir', saveDir, 'firstDateToPlot', firstDateToPlot, 'excludedSessions', excludedSessions ...
);
% L minus S splatter
OLPlotValidationTimeSeries(...
'approachName', 'OLApproach_Squint', ...
'protocolName', 'Deuteranopes', ...
'objectType',   'DirectionObjects', ...
'objectName',   'MaxLMSDirection', ...
'visualizedProperty' , 'LMinusSContrast', ...
'visualizedStatistics', 'medians and data points', ...
'experimentName', experimentName, ...
'excludedSubjectNames', excludedSubjectNames, ...
'yLim', [-0.3 0.3], 'limits', [-0.2 0.2], 'calibrations', calibrations, 'saveDir', saveDir, 'firstDateToPlot', firstDateToPlot, 'excludedSessions', excludedSessions ...
);
% Mel splatter
OLPlotValidationTimeSeries(...
'approachName', 'OLApproach_Squint', ...
'protocolName', 'Deuteranopes', ...
'objectType',   'DirectionObjects', ...
'objectName',   'MaxLMSDirection', ...
'visualizedProperty' , 'MelanopsinContrast', ...
'visualizedStatistics', 'medians and data points', ...
'experimentName', experimentName, ...
'excludedSubjectNames', excludedSubjectNames, ...
'yLim', [-0.3 0.3], 'limits', [-0.2 0.2], 'calibrations', calibrations, 'saveDir', saveDir, 'firstDateToPlot', firstDateToPlot, 'excludedSessions', excludedSessions ...
);
%background luminance
OLPlotValidationTimeSeries(...
'approachName', 'OLApproach_Squint', ...
'protocolName', 'Deuteranopes', ...
'objectType',   'DirectionObjects', ...
'objectName',   'MaxLMSDirection', ...
'visualizedProperty' , 'backgroundLuminance', ...
'visualizedStatistics', 'medians and data points', ...
'experimentName', experimentName, ...
'excludedSubjectNames', excludedSubjectNames, ...
'yLim', [100 200], 'limits', [100 200], 'calibrations', calibrations, 'saveDir', saveDir, 'firstDateToPlot', firstDateToPlot, 'excludedSessions', excludedSessions ...
);

% Melanopsin Modulations
% LS splatter
OLPlotValidationTimeSeries(...
'approachName', 'OLApproach_Squint', ...
'protocolName', 'Deuteranopes', ...
'objectType',   'DirectionObjects', ...
'objectName',   'MaxMelDirection', ...
'visualizedProperty' , 'LSContrast', ...
'visualizedStatistics', 'medians and data points', ...
'experimentName', experimentName, ...
'excludedSubjectNames', excludedSubjectNames, ...
'yLim', [-0.3 0.3], 'limits', [-0.2 0.2], 'calibrations', calibrations, 'saveDir', saveDir, 'firstDateToPlot', firstDateToPlot, 'excludedSessions', excludedSessions ...
);
% L minus S splatter
OLPlotValidationTimeSeries(...
'approachName', 'OLApproach_Squint', ...
'protocolName', 'Deuteranopes', ...
'objectType',   'DirectionObjects', ...
'objectName',   'MaxMelDirection', ...
'visualizedProperty' , 'LMinusSContrast', ...
'visualizedStatistics', 'medians and data points', ...
'experimentName', experimentName, ...
'excludedSubjectNames', excludedSubjectNames, ...
'yLim', [-0.3 0.3], 'limits', [-0.2 0.2], 'calibrations', calibrations, 'saveDir', saveDir, 'firstDateToPlot', firstDateToPlot, 'excludedSessions', excludedSessions ...
);
% Mel contrast
OLPlotValidationTimeSeries(...
'approachName', 'OLApproach_Squint', ...
'protocolName', 'Deuteranopes', ...
'objectType',   'DirectionObjects', ...
'objectName',   'MaxMelDirection', ...
'visualizedProperty' , 'MelanopsinContrast', ...
'visualizedStatistics', 'medians and data points', ...
'experimentName', experimentName, ...
'excludedSubjectNames', excludedSubjectNames, ...
'yLim', [3.25 4.25], 'limits', [3.5 4.25], 'calibrations', calibrations, 'saveDir', saveDir, 'firstDateToPlot', firstDateToPlot, 'excludedSessions', excludedSessions ...
);
%background luminance
OLPlotValidationTimeSeries(...
'approachName', 'OLApproach_Squint', ...
'protocolName', 'Deuteranopes', ...
'objectType',   'DirectionObjects', ...
'objectName',   'MaxMelDirection', ...
'visualizedProperty' , 'backgroundLuminance', ...
'visualizedStatistics', 'medians and data points', ...
'experimentName', experimentName, ...
'excludedSubjectNames', excludedSubjectNames, ...
'yLim', [350 650], 'limits', [350 650], 'calibrations', calibrations, 'saveDir', saveDir, 'firstDateToPlot', firstDateToPlot, 'excludedSessions', excludedSessions ...
);

% LightFlux Modulations
% LS contrast
OLPlotValidationTimeSeries(...
'approachName', 'OLApproach_Squint', ...
'protocolName', 'Deuteranopes', ...
'objectType',   'DirectionObjects', ...
'objectName',   'LightFluxDirection', ...
'visualizedProperty' , 'LSContrast', ...
'visualizedStatistics', 'medians and data points', ...
'experimentName', experimentName, ...
'excludedSubjectNames', excludedSubjectNames, ...
'yLim', [3.25 4.25], 'limits', [3.5 4.25], 'calibrations', calibrations, 'saveDir', saveDir, 'firstDateToPlot', firstDateToPlot, 'excludedSessions', excludedSessions ...
);
% L minus S splatter
OLPlotValidationTimeSeries(...
'approachName', 'OLApproach_Squint', ...
'protocolName', 'Deuteranopes', ...
'objectType',   'DirectionObjects', ...
'objectName',   'LightFluxDirection', ...
'visualizedProperty' , 'LMinusSContrast', ...
'visualizedStatistics', 'medians and data points', ...
'experimentName', experimentName, ...
'excludedSubjectNames', excludedSubjectNames, ...
'yLim', [-0.3 0.3], 'limits', [-0.2 0.2], 'calibrations', calibrations, 'saveDir', saveDir, 'firstDateToPlot', firstDateToPlot, 'excludedSessions', excludedSessions ...
);
% Mel contrast
OLPlotValidationTimeSeries(...
'approachName', 'OLApproach_Squint', ...
'protocolName', 'Deuteranopes', ...
'objectType',   'DirectionObjects', ...
'objectName',   'LightFluxDirection', ...
'visualizedProperty' , 'MelanopsinContrast', ...
'visualizedStatistics', 'medians and data points', ...
'experimentName', experimentName, ...
'excludedSubjectNames', excludedSubjectNames, ...
'yLim', [3.25 4.25], 'limits', [3.5 4.25], 'calibrations', calibrations, 'saveDir', saveDir, 'firstDateToPlot', firstDateToPlot, 'excludedSessions', excludedSessions ...
);
%background luminance
OLPlotValidationTimeSeries(...
'approachName', 'OLApproach_Squint', ...
'protocolName', 'Deuteranopes', ...
'objectType',   'DirectionObjects', ...
'objectName',   'LightFluxDirection', ...
'visualizedProperty' , 'backgroundLuminance', ...
'visualizedStatistics', 'medians and data points', ...
'experimentName', experimentName, ...
'excludedSubjectNames', excludedSubjectNames, ...
'yLim', [200 500], 'limits', [200 500], 'calibrations', calibrations, 'saveDir', saveDir, 'firstDateToPlot', firstDateToPlot, 'excludedSessions', excludedSessions ...
);
%% Experiment 2
experimentName = 'experiment_2';
saveDir = fullfile(getpref('OLApproach_Squint', 'DataPath'), '../MELA_analysis/Experiments/OLApproach_Squint/Deuteranopes/admin', experimentName);

% LS Modulations
% LS contrast
OLPlotValidationTimeSeries(...
'approachName', 'OLApproach_Squint', ...
'protocolName', 'Deuteranopes', ...
'objectType',   'DirectionObjects', ...
'objectName',   'MaxLMSDirection', ...
'visualizedProperty' , 'LSContrast', ...
'visualizedStatistics', 'medians and data points', ...
'experimentName', experimentName, ...
'excludedSubjectNames', excludedSubjectNames, ...
'yLim', [10 12.5], 'limits', [10.5 12.5], 'calibrations', calibrations, 'saveDir', saveDir, 'firstDateToPlot', firstDateToPlot, 'excludedSessions', excludedSessions ...
);
% L minus S splatter
OLPlotValidationTimeSeries(...
'approachName', 'OLApproach_Squint', ...
'protocolName', 'Deuteranopes', ...
'objectType',   'DirectionObjects', ...
'objectName',   'MaxLMSDirection', ...
'visualizedProperty' , 'LMinusSContrast', ...
'visualizedStatistics', 'medians and data points', ...
'experimentName', experimentName, ...
'excludedSubjectNames', excludedSubjectNames, ...
'yLim', [-1 1], 'limits', [-0.5 0.5], 'calibrations', calibrations, 'saveDir', saveDir, 'firstDateToPlot', firstDateToPlot, 'excludedSessions', excludedSessions ...
);
% Mel splatter
OLPlotValidationTimeSeries(...
'approachName', 'OLApproach_Squint', ...
'protocolName', 'Deuteranopes', ...
'objectType',   'DirectionObjects', ...
'objectName',   'MaxLMSDirection', ...
'visualizedProperty' , 'MelanopsinContrast', ...
'visualizedStatistics', 'medians and data points', ...
'experimentName', experimentName, ...
'excludedSubjectNames', excludedSubjectNames, ...
'yLim', [-0.3 0.3], 'limits', [-0.2 0.2], 'calibrations', calibrations, 'saveDir', saveDir, 'firstDateToPlot', firstDateToPlot, 'excludedSessions', excludedSessions ...
);
%background luminance
OLPlotValidationTimeSeries(...
'approachName', 'OLApproach_Squint', ...
'protocolName', 'Deuteranopes', ...
'objectType',   'DirectionObjects', ...
'objectName',   'MaxLMSDirection', ...
'visualizedProperty' , 'backgroundLuminance', ...
'visualizedStatistics', 'medians and data points', ...
'experimentName', experimentName, ...
'excludedSubjectNames', excludedSubjectNames, ...
'yLim', [100 200], 'limits', [100 200], 'calibrations', calibrations, 'saveDir', saveDir, 'firstDateToPlot', firstDateToPlot, 'excludedSessions', excludedSessions ...
);


% Melanopsin Modulations
% LS splatter
OLPlotValidationTimeSeries(...
'approachName', 'OLApproach_Squint', ...
'protocolName', 'Deuteranopes', ...
'objectType',   'DirectionObjects', ...
'objectName',   'MaxLMSDirection', ...
'visualizedProperty' , 'backgroundLuminance', ...
'visualizedStatistics', 'medians and data points', ...
'experimentName', experimentName, ...
'excludedSubjectNames', excludedSubjectNames, ...
'yLim', [0 200], 'limits', [0 200], 'calibrations', calibrations, 'saveDir', saveDir, 'firstDateToPlot', firstDateToPlot, 'excludedSessions', excludedSessions ...
);
% L minus S splatter
OLPlotValidationTimeSeries(...
'approachName', 'OLApproach_Squint', ...
'protocolName', 'Deuteranopes', ...
'objectType',   'DirectionObjects', ...
'objectName',   'MaxMelDirection', ...
'visualizedProperty' , 'LMinusSContrast', ...
'visualizedStatistics', 'medians and data points', ...
'experimentName', experimentName, ...
'excludedSubjectNames', excludedSubjectNames, ...
'yLim', [-0.3 0.3], 'limits', [-0.2 0.2], 'calibrations', calibrations, 'saveDir', saveDir, 'firstDateToPlot', firstDateToPlot, 'excludedSessions', excludedSessions ...
);
% Mel contrast
OLPlotValidationTimeSeries(...
'approachName', 'OLApproach_Squint', ...
'protocolName', 'Deuteranopes', ...
'objectType',   'DirectionObjects', ...
'objectName',   'MaxMelDirection', ...
'visualizedProperty' , 'MelanopsinContrast', ...
'visualizedStatistics', 'medians and data points', ...
'experimentName', experimentName, ...
'excludedSubjectNames', excludedSubjectNames, ...
'yLim', [10 12.5], 'limits', [10.5 12.5], 'calibrations', calibrations, 'saveDir', saveDir, 'firstDateToPlot', firstDateToPlot, 'excludedSessions', excludedSessions ...
);

% LightFlux Modulations
% LS contrast
OLPlotValidationTimeSeries(...
'approachName', 'OLApproach_Squint', ...
'protocolName', 'Deuteranopes', ...
'objectType',   'DirectionObjects', ...
'objectName',   'LightFluxDirection', ...
'visualizedProperty' , 'LSContrast', ...
'visualizedStatistics', 'medians and data points', ...
'experimentName', experimentName, ...
'excludedSubjectNames', excludedSubjectNames, ...
'yLim', [10 12.5], 'limits', [10.5 12.5], 'calibrations', calibrations, 'saveDir', saveDir, 'firstDateToPlot', firstDateToPlot, 'excludedSessions', excludedSessions ...
);
% L minus S splatter
OLPlotValidationTimeSeries(...
'approachName', 'OLApproach_Squint', ...
'protocolName', 'Deuteranopes', ...
'objectType',   'DirectionObjects', ...
'objectName',   'LightFluxDirection', ...
'visualizedProperty' , 'LMinusSContrast', ...
'visualizedStatistics', 'medians and data points', ...
'experimentName', experimentName, ...
'excludedSubjectNames', excludedSubjectNames, ...
'yLim', [-0.3 0.3], 'limits', [-0.2 0.2], 'calibrations', calibrations, 'saveDir', saveDir, 'firstDateToPlot', firstDateToPlot, 'excludedSessions', excludedSessions ...
);
% Mel contrast
OLPlotValidationTimeSeries(...
'approachName', 'OLApproach_Squint', ...
'protocolName', 'Deuteranopes', ...
'objectType',   'DirectionObjects', ...
'objectName',   'LightFluxDirection', ...
'visualizedProperty' , 'MelanopsinContrast', ...
'visualizedStatistics', 'medians and data points', ...
'experimentName', experimentName, ...
'excludedSubjectNames', excludedSubjectNames, ...
'yLim', [10 12.5], 'limits', [10.5 12.5], 'calibrations', calibrations, 'saveDir', saveDir, 'firstDateToPlot', firstDateToPlot, 'excludedSessions', excludedSessions ...
);

close all