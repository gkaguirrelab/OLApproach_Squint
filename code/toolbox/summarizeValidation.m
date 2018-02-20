function validation = summarizeValidation(DirectionStruct, varargin)

%% Parse input
p = inputParser; p.KeepUnmatched = true;

p.addParameter('whichValidation','combined',@ischar);
p.addParameter('plot','on',@ischar);
p.addParameter('verbose','off',@ischar);


p.parse(varargin{:});


potentialValidations = fieldnames(DirectionStruct.describe);

for ii = 1:length(potentialValidations)
    if strcmp(potentialValidations{ii}, 'nominal') || strcmp(potentialValidations{ii}, 'correction')
        potentialValidations{ii} = [];
    end
end
potentialValidations  = potentialValidations(~cellfun('isempty', potentialValidations));

for vv = 1:length(potentialValidations)
    
    validation.LConeContrast(vv) = DirectionStruct.describe.(potentialValidations{vv}).actualContrast(1,1);
    validation.MConeContrast(vv) = DirectionStruct.describe.(potentialValidations{vv}).actualContrast(2,1);
    validation.SConeContrast(vv) = DirectionStruct.describe.(potentialValidations{vv}).actualContrast(3,1);
    validation.MelanopsinContrast(vv) = DirectionStruct.describe.(potentialValidations{vv}).actualContrast(4,1);
    
    validation.LMSContrast(vv) = DirectionStruct.describe.(potentialValidations{vv}).actualContrastPostReceptoral(1,1);
    validation.LMinusMContrast(vv) = DirectionStruct.describe.(potentialValidations{vv}).actualContrastPostReceptoral(2,1);
    validation.SMinusLMContrast(vv) = DirectionStruct.describe.(potentialValidations{vv}).actualContrastPostReceptoral(3,1);
    
end

if strcmp(p.Results.plot, 'on')
    
    % make a big plot
    set(gcf,'un','n','pos',[.05,.05,.7,.6])
    SConeContrastVector = cell2mat({validation.SMinusLMContrast});
    LMSContrastVector = cell2mat({validation.LMSContrast});
    LMinusMContrastVector = cell2mat({validation.LMinusMContrast});
    MelanopsinContrastVector = cell2mat({validation.MelanopsinContrast});
    
    
    title(DirectionStruct.describe.nominal.directionParams.name, 'Interpreter', 'none');
    
    
    
    % determine the appropriate y-axis limits
    if strcmp(DirectionStruct.describe.nominal.directionParams.name, 'MaxLMS_unipolar_275_60_667')
        intendedContrastVector = LMSContrastVector;
        splatterVectors = [SConeContrastVector LMinusMContrastVector MelanopsinContrastVector];
    elseif strcmp(DirectionStruct.describe.nominal.directionParams.name, 'MaxMel_unipolar_275_60_667')
        intendedContrastVector = MelanopsinContrastVector;
        splatterVectors = [SConeContrastVector LMinusMContrastVector LMSContrastVector];
    elseif strcmp(DirectionStruct.describe.nominal.directionParams.name, 'LightFlux_540_380_50')
        intendedContrastVector = LMSContrastVector;
        splatterVectors = [SConeContrastVector LMinusMContrastVector MelanopsinContrastVector];
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
    
    % some flexibility with plotting depending on which validation
    % measurements we're looking at
    if length(potentialValidations) == 5;
        catIdxInstance = zeros(1,5);
        catIdx = horzcat(catIdxInstance, catIdxInstance, catIdxInstance, catIdxInstance)';
        [test] = plotSpread(data, 'distributionMarkers', 'o', 'xNames', {'S Cone', 'L-M', 'LMS', 'Melanopsin'});
        preOrPost = extractAfter(potentialValidations{1}, 'validate');
        preOrPost = preOrPost(1:end-1);
        text(0.25, (yIntendedMax+yIntendedMin)/2, sprintf('o: %s-Experiment', preOrPost))


    elseif length(potentialValidations) == 10;
        catIdxInstance = horzcat(zeros(1,5), ones(1,5));
        catIdx = horzcat(catIdxInstance, catIdxInstance, catIdxInstance, catIdxInstance)';
        [test] = plotSpread(data, 'categoryIdx', catIdx, 'categoryMarkers', {'o', '+'}, 'categoryLabels', {'Pre-Experiment', 'Post-Experiment'}, 'xNames', {'S Cone', 'L-M', 'LMS', 'Melanopsin'}, 'showMM', 3);
        text(0.25, (yIntendedMax+yIntendedMin)/2, sprintf('o: Pre-Experiment \n+: Post-Experiment'))
    end
    if yIntendedMin - ySplatterMax < 100
    else
        
        % apply y-axis break to more cleanly show all validation
        % measurements on 1 subplot
        [test] = breakyaxis([ySplatterMax yIntendedMin], 0.01, 0.1);
    end
    
end

end