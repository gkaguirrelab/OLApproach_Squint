function validation = summarizeValidation(DirectionObject, varargin)

%% Parse input
p = inputParser; p.KeepUnmatched = true;

p.addParameter('whichValidationPrefix','all',@ischar);
p.addParameter('plot','on',@ischar);
p.addParameter('verbose','off',@ischar);


p.parse(varargin{:});


potentialValidations = length(DirectionObject.describe.validation);
validationIndices = [];
for ii = 1:potentialValidations
    if contains(DirectionObject.describe.validation(ii).label, p.Results.whichValidationPrefix) || strcmp(p.Results.whichValidationPrefix, 'all')
        validationIndices = [validationIndices, ii];
    end
end

counter = 1;
for vv = validationIndices
    
    validation.LConeContrast(counter) = DirectionObject.describe.validation(vv).contrastActual(1,1);
    validation.MConeContrast(counter) = DirectionObject.describe.validation(vv).contrastActual(2,1);
    validation.SConeContrast(counter) = DirectionObject.describe.validation(vv).contrastActual(3,1);
    validation.MelanopsinContrast(counter) = DirectionObject.describe.validation(vv).contrastActual(4,1);
    
    validation.LMSContrast(counter) = DirectionObject.describe.validation(vv).postreceptoralContrastActual(1,1);
    validation.LMinusMContrast(counter) = DirectionObject.describe.validation(vv).postreceptoralContrastActual(2,1);
    validation.SMinusLMContrast(counter) = DirectionObject.describe.validation(vv).postreceptoralContrastActual(3,1);
    
    %validation.backgroundLuminance(vv) = DirectionObject.describe.(potentialValidations{vv}).actualBackgroundLuminance;
    
    validation.backgroundLuminance(counter) = DirectionObject.describe.validation(vv).luminanceActual(1);
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