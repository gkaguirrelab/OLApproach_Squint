function [ trialTypeOrder ] = makeTrialOrder(protocolParams)
% Function to determine the trial order for the OLApproach_Squint experiment, based on the sessionNumber and acquisitionNumber.
%
% Syntax:
%  [ trialTypeOrder ] = makeTrialOrder(protocolParams)

% Description:
%   We use several deBuijn sequences to determine the trial order within a
%   given acquisition. This function determines which deBruijn sequence to
%   use, based on which session and which acquisition.

% Inputs:
%   protocolParams        - A structure that defines aspects of the
%                           experiment. The only relevant fields for this
%                           function are protocolParams.sessionName (i.e.
%                           'session_1') and protocolParams.acquisitionNumber 
%                           (i.e. 1)
%
% Outputs:
%   trialTypeOrder        - A 1x10 element vector where each element
%                           corresponds to a given trial, and the value of that element specifies
%                           the stimulus type. The identify of each stimulus can be decoded from
%                           position in this matrix: 
%                           [Mel400PulseModulationData; Mel200PulseModulationData; Mel100PulseModulationData; ...
%                           LMS400PulseModulationData; LMS200PulseModulationData; LMS100PulseModulationData; ...
%                           LightFlux400PulseModulationData; LightFlux200PulseModulationData; LightFlux100PulseModulationData];
%                             



% deBruijn sequences: we want to use deBruijn sequences to counter-balance
% the order of trial types within a given acquisition
deBruijnSequences = ...
    [3,     3,     1,     2,     1,     1,     3,     2,     2;
    3,     1,     2,     2,     1,     1,     3,     3,     2;
    2,     2,     3,     1,     1,     2,     1,     3,     3;
    2,     3,     3,     1,     1,     2,     2,     1,     3;
    3,     3,     1,     2,     1,     1,     3,     2,     2;
    3,     1,     2,     2,     1,     1,     3,     3,     2;
    2,     2,     3,     1,     1,     2,     1,     3,     3;
    2,     3,     3,     1,     1,     2,     2,     1,     3];
% each row here refers to a differnt deBruijn sequence governing trial
% order within each acquisition. Each different label refers (1, 2, or 3) to a
% different contrast level

% when it comes time to actually run an acquisition below, we'll grab a
% row from this deBruijnSequences matrix, and use that row to provide the
% trial order for that acqusition.

triplets = ...
    {'Mel', 'LMS', 'LightFlux'; ...
    'Mel', 'LightFlux', 'LMS'; ...
    'LightFlux', 'Mel', 'LMS'; ...
    'LightFlux', 'LMS', 'Mel'; ...
    'LMS', 'Mel', 'LightFlux'; ...
    'LMS', 'LightFlux', 'Mel';};

if strcmp(protocolParams.sessionName, 'session_1')
    acquisitionOrder = [triplets(1,:), triplets(2,:)];
    sessionNumber = 1;
    
elseif strcmp(protocolParams.sessionName, 'session_2')
    acquisitionOrder = [triplets(3,:), triplets(4,:)];
    sessionNumber = 2;
    
elseif strcmp(protocolParams.sessionName, 'session_3')
    acquisitionOrder = [triplets(5,:), triplets(6,:)];
    sessionNumber = 3;
    
elseif strcmp(protocolParams.sessionName, 'session_4')
    acquisitionOrder = [triplets(1,:), triplets(2,:)];
    sessionNumber = 4;
    
end


if strcmp(acquisitionOrder{protocolParams.acquisitionNumber}, 'Mel') % If the acqusition is Mel
    % grab a specific deBruijn sequence, and append a duplicate of the
    % last trial as the first trial
    % update the counter
    melIndices = find(strcmp(acquisitionOrder, 'Mel'));
    if melIndices(1) == protocolParams.acquisitionNumber
        whichDeBruijn = sessionNumber*2 - 1;
    elseif melIndices(2) == protocolParams.acquisitionNumber
        whichDeBruijn = sessionNumber*2;
    end
    trialTypeOrder = [deBruijnSequences(whichDeBruijn,length(deBruijnSequences(whichDeBruijn,:))), deBruijnSequences(whichDeBruijn,:)];
    
elseif strcmp(acquisitionOrder{protocolParams.acquisitionNumber}, 'LMS')
    lmsIndices = find(strcmp(acquisitionOrder, 'LMS'));
    if lmsIndices(1) == protocolParams.acquisitionNumber
        whichDeBruijn = sessionNumber*2 - 1;
    elseif lmsIndices(2) == protocolParams.acquisitionNumber
        whichDeBruijn = sessionNumber*2;
    end
    trialTypeOrder = [deBruijnSequences(whichDeBruijn,length(deBruijnSequences(whichDeBruijn,:)))+3, deBruijnSequences(whichDeBruijn,:)+3];
    
elseif strcmp(acquisitionOrder{protocolParams.acquisitionNumber}, 'LightFlux')
    LightFluxIndices = find(strcmp(acquisitionOrder, 'LightFlux'));
    if LightFluxIndices(1) == protocolParams.acquisitionNumber
        whichDeBruijn = sessionNumber*2 - 1;
    elseif LightFluxIndices(2) == protocolParams.acquisitionNumber
        whichDeBruijn = sessionNumber*2;
    end
    trialTypeOrder = [deBruijnSequences(whichDeBruijn,length(deBruijnSequences(whichDeBruijn,:)))+6, deBruijnSequences(whichDeBruijn,:)+6];
end

end
