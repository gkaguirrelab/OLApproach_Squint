function [ passStatus] =  applyValidationExclusionCriteria(validation, DirectionObject, varargin)

%% Parse input
p = inputParser; p.KeepUnmatched = true;

p.addParameter('whichValidation','combined',@ischar);
p.addParameter('plot','on',@ischar);
p.addParameter('verbose','off',@ischar);


p.parse(varargin{:});

%% set up the criteria
splatterLimit = 0.2;
minTargetedContrast = 3.5;

failStatus = 0;
%% apply the failure criteria
targetedReceptors = DirectionObject.describe.directionParams.whichReceptorsToIsolate;

if isequal(targetedReceptors, [1, 2, 3]) % LMS pulses
    if abs(median(validation.LMSContrast)) < minTargetedContrast
        failStatus = failStatus + 1;
        if strcmp(p.Results.verbose, 'on')
            
            sprintf('LMS contrast for LMS stimulation too low')
        end
    end
    if abs(median(validation.SMinusLMContrast)) > splatterLimit
        failStatus = failStatus + 1;
        if strcmp(p.Results.verbose, 'on')
            
            sprintf('SCone contrast for LMS stimulation too high')
        end
    end
    if abs(median(validation.LMinusMContrast)) > splatterLimit
        failStatus = failStatus + 1;
        if strcmp(p.Results.verbose, 'on')
            
            sprintf('L-M contrast for LMS stimulation too high')
        end
    end
    if abs(median(validation.MelanopsinContrast)) > splatterLimit
        failStatus = failStatus + 1;
        if strcmp(p.Results.verbose, 'on')
            
            sprintf('Melanopsin contrast for LMS stimulation too high')
        end
    end
end

% for melanopsin stimuli, apply the exlcusion criteria
if isequal(targetedReceptors, [4]) % mel pulses
    
    if abs(median(validation.MelanopsinContrast)) < minTargetedContrast
        failStatus = failStatus + 1;
        if strcmp(p.Results.verbose, 'on')
            
            sprintf('Melanopsin contrast for Melanopsin stimulation too low')
        end
    end
    if abs(median(validation.SMinusLMContrast)) > splatterLimit
        failStatus = failStatus + 1;
        if strcmp(p.Results.verbose, 'on')
            
            sprintf('SCone contrast for Melanopsin stimulation too high')
        end
        
    end
    if abs(median(validation.LMinusMContrast)) > splatterLimit
        failStatus = failStatus + 1;
        if strcmp(p.Results.verbose, 'on')
            
            sprintf('L-M contrast for Melanopsin stimulation too high')
        end
        
    end
    if abs(median(validation.LMSContrast)) > splatterLimit
        failStatus = failStatus + 1;
        if strcmp(p.Results.verbose, 'on')
            
            sprintf('LMS contrast for Melanopsin stimulation too high')
        end
        
    end
end

if isequal(targetedReceptors, [1, 2, 3, 4]) % mel/LMS combined pulses
    
    if abs(median(validation.MelanopsinContrast)) < minTargetedContrast
        failStatus = failStatus + 1;
        if strcmp(p.Results.verbose, 'on')
            
            sprintf('Melanopsin contrast for Mel/LMS combined stimulation too low')
        end
    end
    if abs(median(validation.SMinusLMContrast)) > splatterLimit
        failStatus = failStatus + 1;
        if strcmp(p.Results.verbose, 'on')
            
            sprintf('SCone contrast for Mel/LMS combined stimulation too high')
        end
        
    end
    if abs(median(validation.LMinusMContrast)) > splatterLimit
        failStatus = failStatus + 1;
        if strcmp(p.Results.verbose, 'on')
            
            sprintf('L-M contrast for Mel/LMS combined stimulation too high')
        end
        
    end
    if abs(median(validation.LMSContrast)) < minTargetedContrast
        failStatus = failStatus + 1;
        if strcmp(p.Results.verbose, 'on')
            
            sprintf('LMS contrast for Mel/LMS combined stimulation too low')
        end
        
    end
end




if failStatus > 0
    passStatus = 0;
else
    passStatus = 1;
end

end