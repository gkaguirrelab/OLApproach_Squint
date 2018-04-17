function [ trialTypeOrder ] = makeTrialOrder(protocolParams)

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
