% This routine serves as a wrapper around the OLPlotValidationTimeSeries
% function that lives within the OneLightToolbox. Basically this routine
% will plot 1) all contrast and splatter for each stimulus type, 2)
% background luminance for light flux (which is used to determine when we
% need to change ND filters to maintain consistent overall light levels),
% and 3) box temperature.


% the OLPlotValidationTimeSeries routine automatically looks within the
% MELA_data/Experiment/OLApproach_Squint/DirectionObjects to pool all
% sessions together. Various subjectIDs in that folder are not relevant,
% most often because they were part of testing. The variable
% excludedSubjects is then passed into OLPlotValidationTimeSeries, and
% these subjectIDs are exlcluded from the plotting


% notes about some funny subjects:
% subject notes:
% MELA_0126: no showed for session 3 on 6/25
% MELA_0127: for session 1 on 6/28, oneLight failed
% MELA_0121: for session 2 on 5/2, aborted because of tech failure
% MELA_0134: for session 1 on 5/3, actually a screening experiment 
% MELA_0147: for session 3 on 7/25, no showed because was in the midst of a
% migraine
% MELA_0147: for session 3 on 7/27, no (again) showed because was in the midst of a
% migraine
% MELA_0120: for session 3 on 08/24, the box failed. this is actually what
% prompted us to switch to box A
% MELA_0150: for session 1 and 2 on 9/17, the background luminance is quite
% dim for the post-val for Session 1 and for the pre-val for session 2. We
% initially considered if this was a result of bulb cooldown following
% needing to restart the OneLight due to connectivity issues. However, we
% have done this procedure before with no corresponding loss of luminance
% (multiple times, in fact). Also, the relationship between temperature and
% luminance isn't as expected: the magnitude of temperature change doesn't
% seem particularly large relative to what we've seen in other experiments,
% and sometimes temperature has increased while luminance has decreased.
% More likely, one end of the liquid light guide wasn't plugged in all of
% the way.


excludedSubjectNames = {'HERO_instantiationCheck', 'boxAModulationCheck', 'temperatureCheck', 'BoxD_ND02', 'BoxA_ND09', 'BoxA_ND07', 'tortureTest_boxD_1', 'boxA_ND10', 'boxA_ND07_LMSAdjustments', 'test'};
for ii = 1:56
excludedSubjectNames{end+1} = ['tortureTest_', num2str(ii)];
end
for ii = 1:70
excludedSubjectNames{end+1} = ['tortureTest_day2_', num2str(ii)];
end
for ii = 2:17
    excludedSubjectNames{end+1} = ['tortureTest_boxD_', num2str(ii)];
end
for ii = 1:52
    excludedSubjectNames{end+1} = ['tortureTest_boxD_postSurgery_', num2str(ii)];
end

excludedSessions.names = {'MELA_0120', 'MELA_0147'};
excludedSessions.dates = {'2018-08-24_session_3', '2018-08-29_session_3'};

% additional optional key-value pairs for plotting
calibrations = {'2018-05-29', '2018-07-11', '2018-09-05', '2018-10-10', '2018-11-13', '2018-12-06'}; % when relevant calibrations happened. 2018-05-29 -> when we switched form ND 0.4 to 0.3. 2018-07-11 -> when we switched from ND 0.3 to 0.2.
% 2018-09-05: switched to Box A, with ND 0.7 cable

% where we're saving these plots
saveDir = fullfile(getpref('OLApproach_Squint', 'DataPath'), '../MELA_analysis/Experiments/OLApproach_Squint/SquintToPulse/admin');
firstDateToPlot = '2018-12-05';
%% LMS validations
OLPlotValidationTimeSeries(...
'approachName', 'OLApproach_Squint', ...
'protocolName', 'SquintToPulse', ...
'objectType',   'DirectionObjects', ...
'objectName',   'MaxLMSDirection', ...
'visualizedProperty' , 'SMinusLMContrast', ...
'visualizedStatistics', 'medians and data points', ...
'excludedSubjectNames', excludedSubjectNames, ...
'yLim', [-0.3 0.3], 'limits', [-0.2 0.2], 'calibrations', calibrations, 'saveDir', saveDir, 'firstDateToPlot', firstDateToPlot, 'excludedSessions', excludedSessions ...
);

OLPlotValidationTimeSeries(...
'approachName', 'OLApproach_Squint', ...
'protocolName', 'SquintToPulse', ...
'objectType',   'DirectionObjects', ...
'objectName',   'MaxLMSDirection', ...
'visualizedProperty' , 'LMinusMContrast', ...
'visualizedStatistics', 'medians and data points', ...
'excludedSubjectNames', excludedSubjectNames, ...
'yLim', [-0.3 0.3], 'limits', [-0.2 0.2], 'calibrations', calibrations, 'saveDir', saveDir, 'firstDateToPlot', firstDateToPlot, 'excludedSessions', excludedSessions  ...
);

OLPlotValidationTimeSeries(...
'approachName', 'OLApproach_Squint', ...
'protocolName', 'SquintToPulse', ...
'objectType',   'DirectionObjects', ...
'objectName',   'MaxLMSDirection', ...
'visualizedProperty' , 'MelanopsinContrast', ...
'visualizedStatistics', 'medians and data points', ...
'excludedSubjectNames', excludedSubjectNames, ...
'yLim', [-0.3 0.3], 'limits', [-0.2 0.2], 'calibrations', calibrations, 'saveDir', saveDir, 'firstDateToPlot', firstDateToPlot, 'excludedSessions', excludedSessions  ...
);

OLPlotValidationTimeSeries(...
'approachName', 'OLApproach_Squint', ...
'protocolName', 'SquintToPulse', ...
'objectType',   'DirectionObjects', ...
'objectName',   'MaxLMSDirection', ...
'visualizedProperty' , 'LMSContrast', ...
'visualizedStatistics', 'medians and data points', ...
'excludedSubjectNames', excludedSubjectNames, ...
'yLim', [3.25 4.25], 'limits', [3.5 4.25], 'calibrations', calibrations, 'saveDir', saveDir, 'firstDateToPlot', firstDateToPlot, 'excludedSessions', excludedSessions  ...
);

OLPlotValidationTimeSeries(...
'approachName', 'OLApproach_Squint', ...
'protocolName', 'SquintToPulse', ...
'objectType',   'DirectionObjects', ...
'objectName',   'MaxLMSDirection', ...
'visualizedProperty' , 'backgroundLuminance', ...
'visualizedStatistics', 'medians and data points', ...
'excludedSubjectNames', excludedSubjectNames, ...
'yLim', [110 170], 'calibrations', calibrations, 'saveDir', saveDir, 'firstDateToPlot', firstDateToPlot, 'excludedSessions', excludedSessions  ...
);

%% Mel validations
OLPlotValidationTimeSeries(...
'approachName', 'OLApproach_Squint', ...
'protocolName', 'SquintToPulse', ...
'objectType',   'DirectionObjects', ...
'objectName',   'MaxMelDirection', ...
'visualizedProperty' , 'SMinusLMContrast', ...
'visualizedStatistics', 'medians and data points', ...
'excludedSubjectNames', excludedSubjectNames, ...
'yLim', [-0.3 0.3], 'limits', [-0.2 0.2], 'calibrations', calibrations, 'saveDir', saveDir, 'firstDateToPlot', firstDateToPlot, 'excludedSessions', excludedSessions  ...
);

OLPlotValidationTimeSeries(...
'approachName', 'OLApproach_Squint', ...
'protocolName', 'SquintToPulse', ...
'objectType',   'DirectionObjects', ...
'objectName',   'MaxMelDirection', ...
'visualizedProperty' , 'LMinusMContrast', ...
'visualizedStatistics', 'medians and data points', ...
'excludedSubjectNames', excludedSubjectNames, ...
'yLim', [-0.3 0.3], 'limits', [-0.2 0.2], 'calibrations', calibrations, 'saveDir', saveDir, 'firstDateToPlot', firstDateToPlot, 'excludedSessions', excludedSessions  ...
);

OLPlotValidationTimeSeries(...
'approachName', 'OLApproach_Squint', ...
'protocolName', 'SquintToPulse', ...
'objectType',   'DirectionObjects', ...
'objectName',   'MaxMelDirection', ...
'visualizedProperty' , 'LMSContrast', ...
'visualizedStatistics', 'medians and data points', ...
'excludedSubjectNames', excludedSubjectNames, ...
'yLim', [-0.3 0.3], 'limits', [-0.2 0.2], 'calibrations', calibrations, 'saveDir', saveDir, 'firstDateToPlot', firstDateToPlot, 'excludedSessions', excludedSessions  ...
);

OLPlotValidationTimeSeries(...
'approachName', 'OLApproach_Squint', ...
'protocolName', 'SquintToPulse', ...
'objectType',   'DirectionObjects', ...
'objectName',   'MaxMelDirection', ...
'visualizedProperty' , 'MelanopsinContrast', ...
'visualizedStatistics', 'medians and data points', ...
'excludedSubjectNames', excludedSubjectNames, ...
'yLim', [3.25 4.25], 'limits', [3.5 4.25], 'calibrations', calibrations, 'saveDir', saveDir, 'firstDateToPlot', firstDateToPlot, 'excludedSessions', excludedSessions  ...
);

OLPlotValidationTimeSeries(...
'approachName', 'OLApproach_Squint', ...
'protocolName', 'SquintToPulse', ...
'objectType',   'DirectionObjects', ...
'objectName',   'MaxMelDirection', ...
'visualizedProperty' , 'backgroundLuminance', ...
'visualizedStatistics', 'medians and data points', ...
'excludedSubjectNames', excludedSubjectNames, ...
'yLim', [200 400], 'calibrations', calibrations, 'saveDir', saveDir, 'firstDateToPlot', firstDateToPlot, 'excludedSessions', excludedSessions  ...
);

%% LightFlux validations
OLPlotValidationTimeSeries(...
'approachName', 'OLApproach_Squint', ...
'protocolName', 'SquintToPulse', ...
'objectType',   'DirectionObjects', ...
'objectName',   'LightFluxDirection', ...
'visualizedProperty' , 'SMinusLMContrast', ...
'visualizedStatistics', 'medians and data points', ...
'excludedSubjectNames', excludedSubjectNames, ...
'yLim', [-0.3 0.3], 'limits', [-0.2 0.2], 'calibrations', calibrations, 'saveDir', saveDir, 'firstDateToPlot', firstDateToPlot, 'excludedSessions', excludedSessions  ...
);

OLPlotValidationTimeSeries(...
'approachName', 'OLApproach_Squint', ...
'protocolName', 'SquintToPulse', ...
'objectType',   'DirectionObjects', ...
'objectName',   'LightFluxDirection', ...
'visualizedProperty' , 'LMinusMContrast', ...
'visualizedStatistics', 'medians and data points', ...
'excludedSubjectNames', excludedSubjectNames, ...
'yLim', [-0.3 0.3], 'limits', [-0.2 0.2], 'calibrations', calibrations, 'saveDir', saveDir, 'firstDateToPlot', firstDateToPlot, 'excludedSessions', excludedSessions  ...
);

OLPlotValidationTimeSeries(...
'approachName', 'OLApproach_Squint', ...
'protocolName', 'SquintToPulse', ...
'objectType',   'DirectionObjects', ...
'objectName',   'LightFluxDirection', ...
'visualizedProperty' , 'LMSContrast', ...
'visualizedStatistics', 'medians and data points', ...
'excludedSubjectNames', excludedSubjectNames, ...
'yLim', [3.25 4.25], 'limits', [3.5 4.25], 'calibrations', calibrations, 'saveDir', saveDir, 'firstDateToPlot', firstDateToPlot, 'excludedSessions', excludedSessions  ...
);

OLPlotValidationTimeSeries(...
'approachName', 'OLApproach_Squint', ...
'protocolName', 'SquintToPulse', ...
'objectType',   'DirectionObjects', ...
'objectName',   'LightFluxDirection', ...
'visualizedProperty' , 'MelanopsinContrast', ...
'visualizedStatistics', 'medians and data points', ...
'excludedSubjectNames', excludedSubjectNames, ...
'yLim', [3.25 4.25], 'limits', [3.5 4.25], 'calibrations', calibrations, 'saveDir', saveDir, 'firstDateToPlot', firstDateToPlot, 'excludedSessions', excludedSessions  ...
);




%% stimulus non-specific validaitons
OLPlotValidationTimeSeries(...
'approachName', 'OLApproach_Squint', ...
'protocolName', 'SquintToPulse', ...
'objectType',   'DirectionObjects', ...
'objectName',   'LightFluxDirection', ...
'visualizedProperty' , 'backgroundLuminance', ...
'visualizedStatistics', 'medians and data points', ...
'excludedSubjectNames', excludedSubjectNames, ...
'yLim', [150 275], 'limits', [160.685 254.6685], 'calibrations', calibrations, 'saveDir', saveDir, 'firstDateToPlot', firstDateToPlot, 'excludedSessions', excludedSessions  ...
);




OLPlotValidationTimeSeries(...
'approachName', 'OLApproach_Squint', ...
'protocolName', 'SquintToPulse', ...
'objectType',   'DirectionObjects', ...
'objectName',   'LightFluxDirection', ...
'visualizedProperty' , 'boxTemperature', ...
'visualizedStatistics', 'medians and data points', ...
'excludedSubjectNames', excludedSubjectNames, ...
'calibrations', calibrations, 'yLim', [26 35], 'saveDir', saveDir, 'firstDateToPlot', firstDateToPlot, 'excludedSessions', excludedSessions  ...
);