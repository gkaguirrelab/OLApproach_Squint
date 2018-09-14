function [ passStatus] =  applyValidationExclusionCriteria(validation, DirectionObject, varargin)
% Looks at the results contained within a validation structure to decide if
% these validation measurements pass the OLApproach_Squint's specific
% exclusion criteria.
%
% Syntax:
%  [ passStatus] =  applyValidationExclusionCriteria(validation, DirectionObject)

% Description:
%   This function uses the DirectionObject to determine which type of
%   stimulus we're working with. Each stimulus type has certain criteria
%   for both the contrast on the targeted photoreceptors, as well as the
%   splatter on photoreceptor mechanisms nominally silenced , for what
%   constitutes a good stimulus. These criteria are hard-coded below. The
%   routine looks at the results contained within the validation structure,
%   and determines if these validation measurements pass the experiment's
%   pre-registered exclusion criteria.

% Inputs:
%	validation            - A structure containing the validation results,
%                           most likely produced by the function
%                           summarizeValidation
%   DirectionObject       - The direction object for the relevant stimulus
%                           class. This is used to determine the stimulus
%                           type of the validation structure.
% Optional Key-Value Pairs:
%   verbose               - A string that can either be set to 'off' (the
%                           default), or 'on.' If set to 'on,' then the
%                           routine will print to the console which
%                           validation measures, if any, do not pass our
%                           exclusion criteria.
% Outputs:
%   passStatus            - A binary 0 or 1. If 1, these validation
%                           measurements pass exclusion criteria. If 0,
%                           these validation measurements fail exclusion
%                           criteria.





%% Parse input
p = inputParser; p.KeepUnmatched = true;

p.addParameter('verbose','off',@ischar);


p.parse(varargin{:});

%% set up the criteria
splatterLimit = 0.2;
minTargetedContrast = 3.5;

failStatus = 0;

%% apply the failure criteria
if strcmp(DirectionObject.describe.directionParams.baseName, 'LightFlux') % light flux pulses
    if abs(median(validation.LMSContrast)) < minTargetedContrast
        failStatus = failStatus + 1;
        if strcmp(p.Results.verbose, 'on')
            
            sprintf('LMS contrast for Light Flux stimulation too low')
        end
    end
    if abs(median(validation.SMinusLMContrast)) > splatterLimit
        failStatus = failStatus + 1;
        if strcmp(p.Results.verbose, 'on')
            
            sprintf('SCone contrast for Light Flux stimulation too high')
        end
    end
    if abs(median(validation.LMinusMContrast)) > splatterLimit
        failStatus = failStatus + 1;
        if strcmp(p.Results.verbose, 'on')
            
            sprintf('L-M contrast for Light Flux stimulation too high')
        end
    end
    if abs(median(validation.MelanopsinContrast)) < minTargetedContrast
        failStatus = failStatus + 1;
        if strcmp(p.Results.verbose, 'on')
            
            sprintf('Melanopsin contrast for Light Flux stimulation too low')
        end
    end
else
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
end




if failStatus > 0
    passStatus = 0;
else
    passStatus = 1;
end

end