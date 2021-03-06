function validation = summarizeValidation(DirectionObject, varargin)
% Summarizes validation measurements stored within the DirectionObject.
%
% Syntax:
%  [ XYChromaticity, chromaticityAccumulator ] = calculateChromaticity( DirectionObject)

% Description:
%   This function loops through the validation measurements contained within a
%   DirectionObject and packages them into a (potentially) neater
%   structure. If plotting is enabled, the routine will also display a plot
%   of the relevant validation measures for the user.

% Inputs:
%   DirectionObject       - The direction object for the direction in
%                           question. Note that validation is performed on,
%                           and saved into, these direction objects.
% Optional Key-Value Pairs:
%   whichValidationPrefix - A string or cell array of strings that describe
%                           which validation measurments we're trying to
%                           pool. Within the DirectionObject, each
%                           validation measurement can be associated with a
%                           label. If we only want validations with a
%                           corresponding label to be included, we'd
%                           specify the appropriate label or labels with
%                           this key-value pair.
%  plot                   - A string that controls plotting behavior. If
%                           'on', the default, then a plot of validation
%                           measurements will be displayed. If 'off' (or
%                           any other string, really), then no such plot is
%                           shown.

% Outputs:
%   validation            - A structure where each subfield is a different 
%                           validation measurement. The contents of each
%                           subfield is a vector, where each element is the
%                           relevant metric from a single validation
%                           measurement.




%% Parse input
p = inputParser; p.KeepUnmatched = true;
p.addParameter('whichValidationPrefix','all',@ischar);
p.addParameter('plot','on',@ischar);
p.parse(varargin{:});

potentialValidations = length(DirectionObject.describe.validation);
validationIndices = [];
for ii = 1:potentialValidations
    if contains(DirectionObject.describe.validation(ii).label, p.Results.whichValidationPrefix) || strcmp(p.Results.whichValidationPrefix, 'all')
        validationIndices = [validationIndices, ii];
    end
end

% Return empty array if nothing found
if (isempty(validationIndices))
    validation = [];
end

 counter = 1;
 load T_xyz1931
 S = DirectionObject.calibration.describe.S;
 T_xyz = SplineCmf(S_xyz1931,683*T_xyz1931,S);
    
for vv = validationIndices
    
    if length(DirectionObject.describe.directionParams.photoreceptorClasses) == 4
    validation.LConeContrast(counter) = DirectionObject.describe.validation(vv).contrastActual(1,1);
    validation.MConeContrast(counter) = DirectionObject.describe.validation(vv).contrastActual(2,1);
    validation.SConeContrast(counter) = DirectionObject.describe.validation(vv).contrastActual(3,1);
    validation.MelanopsinContrast(counter) = DirectionObject.describe.validation(vv).contrastActual(4,1);
    
    validation.LMSContrast(counter) = DirectionObject.describe.validation(vv).postreceptoralContrastActual(1,1);
    validation.LMinusMContrast(counter) = DirectionObject.describe.validation(vv).postreceptoralContrastActual(2,1);
    validation.SMinusLMContrast(counter) = DirectionObject.describe.validation(vv).postreceptoralContrastActual(3,1);
    else
        validation.LConeContrast(counter) = DirectionObject.describe.validation(vv).contrastActual(1,1);
        validation.SConeContrast(counter) = DirectionObject.describe.validation(vv).contrastActual(2,1);
        validation.MelanopsinContrast(counter) = DirectionObject.describe.validation(vv).contrastActual(3,1);
        validation.LMinusSContrast(counter) = DirectionObject.describe.validation(vv).contrastActual(1,1) - DirectionObject.describe.validation(vv).contrastActual(2,1);
        validation.LSContrast(counter) = mean([DirectionObject.describe.validation(vv).contrastActual(1,1), DirectionObject.describe.validation(vv).contrastActual(2,1)]);
    end
    %validation.backgroundLuminance(vv) = DirectionObject.describe.(potentialValidations{vv}).actualBackgroundLuminance;
    
    validation.backgroundLuminance(counter) = DirectionObject.describe.validation(vv).luminanceActual(1);
    if (isfield(DirectionObject.describe.validation(vv), 'temperatures') && ~isempty(DirectionObject.describe.validation(vv).temperatures))
        validation.boxTemperature(counter) = DirectionObject.describe.validation(vv).temperatures{1}.value(1);
        validation.roomTemperature(counter) = DirectionObject.describe.validation(vv).temperatures{1}.value(2);
    else
        validation.boxTemperature(counter) = NaN;
        validation.roomTemperature(counter) = NaN;
    end
    if isfield(DirectionObject.describe.validation(vv), 'stateTrackingData')
        if (~isempty(DirectionObject.describe.validation(vv).stateTrackingData)) && numel(fieldnames(DirectionObject.describe.validation(vv).stateTrackingData)) ~= 0
            
            allOnSPD = DirectionObject.describe.validation(vv).stateTrackingData.powerFluctuation.spd;
            validation.maxLuminance(counter) = T_xyz(2,:) * [allOnSPD];
        else
            validation.maxLuminance(counter) = NaN;
        end
    else
        validation.maxLuminance(counter) = NaN;
    end
    counter = counter + 1;
end

if strcmp(p.Results.plot, 'on')
    
    % make a big plot
    set(gcf,'un','n','pos',[.05,.05,.7,.6])
    SConeContrastVector = cell2mat({validation.SMinusLMContrast});
    LMSContrastVector = cell2mat({validation.LMSContrast});
    LMinusMContrastVector = cell2mat({validation.LMinusMContrast});
    MelanopsinContrastVector = cell2mat({validation.MelanopsinContrast});
    
    
    directionName = DirectionObject.describe.directionParams.name;
    
    
    title(directionName, 'Interpreter', 'none');
    
    
    
    % determine the appropriate y-axis limits
    if contains(directionName, 'MaxLMS_')
        intendedContrastVector = LMSContrastVector;
        splatterVectors = [SConeContrastVector LMinusMContrastVector MelanopsinContrastVector];
    elseif contains(directionName, 'MaxMel_')
        intendedContrastVector = MelanopsinContrastVector;
        splatterVectors = [SConeContrastVector LMinusMContrastVector LMSContrastVector];
    elseif contains(directionName, 'MaxMelLMS_')
        intendedContrastVector = [LMSContrastVector MelanopsinContrastVector];
        splatterVectors = [SConeContrastVector LMinusMContrastVector];
    elseif contains(directionName, 'LightFlux_')
        intendedContrastVector = [LMSContrastVector MelanopsinContrastVector];
        splatterVectors = [SConeContrastVector LMinusMContrastVector];
    end
    
    % for the direction of interest, the y axis will be bounded
    % between 390 and 410 unless any of the data points are outside
    % that range. in that case, extend the range from that data
    % point further by 5%
    if min(intendedContrastVector*100) < 390
        yIntendedMin = min(intendedContrastVector*100) - 5;
        
    else
        yIntendedMin = 390;
    end
    if max(intendedContrastVector*100) > 410
        yIntendedMax = max(intendedContrastVector*100) + 5;
    else
        yIntendedMax = 410;
    end
    
    % for directions not of interest, the y bounds will be set
    % between -10 and 10 again unless individual data points
    % require that range to be extended
    if min(splatterVectors*100) < -10
        ySplatterMin = min(splatterVectors*100) - 5;
        
    else
        ySplatterMin = -10;
    end
    if max(splatterVectors*100) > 10
        ySplatterMax = max(splatterVectors*100) + 5;
    else
        ySplatterMax = 10;
    end
    
    hold on;
    
    % add lines to show the boundaries of our exclusion criteria
    line([0.5 4.5], [350 350], 'Color', 'r', 'LineStyle', '--');
    line([0.5 4.5], [20 20], 'Color', 'r', 'LineStyle', '--');
    line([0.5 4.5], [-20 -20], 'Color', 'r', 'LineStyle', '--');
    
    ylim([ySplatterMin yIntendedMax]);
    
    
    
    % putting the data together to work with the plotSpread
    % function
    data = horzcat({100*SConeContrastVector', 100*LMinusMContrastVector', 100*LMSContrastVector', 100*MelanopsinContrastVector'});
    
    % determine how many stimulus labels we are working with
    counter = 1;
    for ii = validationIndices
        labelsArray{counter} = DirectionObject.describe.validation(ii).label;
        counter = counter + 1;
    end
    uniqueLabels = unique(labelsArray);
    
    catIdxInstance = [];
    for ii = 1:length(validationIndices)
        for ll = 1:length(uniqueLabels)
            if strcmp(DirectionObject.describe.validation(ii).label, uniqueLabels{ll})
                catIdxInstance(ii) = ll-1;
            end
        end
    end
    
    markers = {'+', 'o', '.', '*', 'o', '+', '.', '*', 'o', '+', '.', '*'};
    catIdx = horzcat(catIdxInstance, catIdxInstance, catIdxInstance, catIdxInstance)';
    [test] = plotSpread(data, 'categoryIdx', catIdx,  'categoryMarkers', {markers{1:length(uniqueLabels)}}, 'categoryLabels', uniqueLabels, 'xNames', {'S Cone', 'L-M', 'LMS', 'Melanopsin'});
    
    textString = [];
    for ll = 1:length(uniqueLabels)
        textString = [textString, markers{ll}, ': ', uniqueLabels{ll}, '\n'];
    end
        
    text(0.25, (yIntendedMax+yIntendedMin)/2, sprintf(textString))

    
    if yIntendedMin - ySplatterMax < 100
    else
        
        % apply y-axis break to more cleanly show all validation
        % measurements on 1 subplot
        [test] = breakyaxis([ySplatterMax yIntendedMin], 0.01, 0.1);
    end
    
end

end