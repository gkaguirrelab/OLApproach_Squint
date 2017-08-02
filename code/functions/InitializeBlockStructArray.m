
function block = InitializeBlockStructArray(protocolParams)
% Initialize
block = struct();
block(protocolParams.nTrials).describe = '';


% BUILDS THE BLOCKS -- THIS SHOULD BE SEPERATED INTO A PREP SCRIPT
for i = 1:protocolParams.nTrials
    fprintf('- Preconfiguring trial %i/%i...', i, protocolParams.nTrials);
    
    % ALL THIS SHOULD BE BE PULLED FROM EITHER DICTIONARY OR
    % MAKESTARTSSTOPS
    
    block(i).data = modulationData{Params.theDirections(i)}.modulationObj.modulation(Params.theFrequencyIndices(i), Params.thePhaseIndices(i), Params.theContrastRelMaxIndices(i));
    block(i).describe = modulationData{Params.theDirections(i)}.modulationObj.describe;
    
    % Check if the 'attentionTask' flag is set. If it is, set up the task
    % (brief stimulus offset).
    block(i).attentionTask.flag = Params.attentionTask(i);
    
    block(i).direction = block(i).data.direction;
    block(i).carrierFrequencyHz = block(i).describe.theFrequenciesHz(Params.theFrequencyIndices(i));
    
    % We pull out the background.
    block(i).data.startsBG = block(i).data.starts(:, 1);
    block(i).data.stopsBG = block(i).data.stops(:, 1);
    
    % WE NEED TO DISCUSS THE ATTENTIONAL TASK AND HOW WE WANT TO IMPLEMENT
    
    if block(i).attentionTask.flag
        nSegments = Params.trialDuration(i)/Params.attentionSegmentDuration;
        
        for s = 1:nSegments; % Iterate over the trials
            % Define the beginning and end of the 30 second esgments
            theStartSegmentIndex = 1/Params.timeStep*Params.attentionSegmentDuration*(s-1)+1;
            theStopSegmentIndex = 1/Params.timeStep*Params.attentionSegmentDuration*s;
            
            % Flip a coin to decide whether we'll have a blank event or not
            theCoinFlip = binornd(1, 1/3);
            
            % If yes, then define what the start and stop indices are for this
            if theCoinFlip
                theStartBlankIndex = randi([theStartSegmentIndex+Params.attentionMarginDuration*1/Params.timeStep theStopSegmentIndex-Params.attentionMarginDuration*1/Params.timeStep]);
                theStopBlankIndex = theStartBlankIndex+Params.attentionBlankDuration*1/Params.timeStep;
                
                % Blank out the settings
                block(i).data.starts(:, theStartBlankIndex:theStopBlankIndex) = 0;
                block(i).data.stops(:, theStartBlankIndex:theStopBlankIndex) = 250;
                
                % Assign a Boolean vector, allowing us to keep track of
                % when it blanked.
                block(i).attentionTask.T(theStartBlankIndex) = 1;
                block(i).attentionTask.T(theStopBlankIndex) = -1;
                
                block(i).attentionTask.segmentFlag(s) = 1;
                block(i).attentionTask.theStartBlankIndex(s) = theStartBlankIndex;
                block(i).attentionTask.theStopBlankIndex(s) = theStopBlankIndex;
            else
                % Assign a Boolean vector, allowing us to keep track of
                % when it blanked.
                block(i).attentionTask.T = 0;
                block(i).attentionTask.T = 0;
                
                block(i).attentionTask.segmentFlag(s) = 0;
                block(i).attentionTask.theStartBlankIndex(s) = -1;
                block(i).attentionTask.theStopBlankIndex(s) = -1;
            end
            
        end
    end
    fprintf('Done\n');
end
end



