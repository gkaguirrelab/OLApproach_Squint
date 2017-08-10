function block = InitializeBlockStructArray(protocolParams,modulationData)
% InitializeBlockStructArray  Sets up block data structure for each trial, including attention task info
%
% Usage:
%     block = InitializeBlockStructArray(protocolParams,modulationData)
%
% Description:
%     The block structure contains trial-by-trial information about the experiemnt such as 
%     start/stops values.  One of the key jobs of this routine is (optionally) to 
%     modify the starts/stops values to include an attention task stimulus, which is a 
%     dimming of the full field.
%
%     It is possible that the attention task code should be yet further factorized into
%     its own separate function.
%     
% Input:
%     protocolParams (struct)            A struct that contain the starts/stops.  Some key fields:
%                                        attentionTask - If true insert attention task.
%                                        [DHB NOTE: IT WOULD BE NICE TO KNOW ABOUT MORE KEY FIELDS HERE.]                
%
% Output:
%     block (struct)                     Contains trial-by-trial starts/stops and other info. 
%
% Optional key/value pairs.
%    None.
%
% See also:

% 8/2/17  mab  Split from experiment and tried to add comments.

%% Initialize
block = struct();

%% Setup for each trial.
%
% Use the trialTypeOrder field of protocolParams to figure out what trial type 
% will be used for each trial.  Get out the starts/stops and insert attention
% event as necessary.
for trial = 1:protocolParams.nTrials
    fprintf('- Preconfiguring trial %i or %i...', trial, protocolParams.nTrials);
    
    block(trial).modulationData = modulationData(protocolParams.trialTypeOrder(trial));
    
    % Check if the 'attentionTask' flag is set. If it is, set up the task
    block(trial).attentionTask.flag = protocolParams.attentionTask;
       
    % Implement attention task
    %
    % Each trial is divided into segments, with the possibility of an attention task event
    % st up independently for each segment.
    if block(trial).attentionTask.flag
        % Figure out how many segments there are per trial
        nSegments = block(trial).modulationData.params.stimulusDuration/protocolParams.attentionSegmentDuration;
        if (nSegments ~= round(nSegments))
            error('attentionSegmentDuration must evenly divide trial duration');
        end     
        segmentDuration = block(trial).modulationData.params.stimulusDuration/nSegments;
        
        % As far as we can tell, the code below was not written to handle the case where there was
        % more than one segment per trial.  One would have to think through indexing from the segment
        % back into indexing into the full starts/stops matrices for the trial to make it work.
        % 
        % One day, we may need more than one attention event per trial, but right now we don't.
        % So, just throw an error for now.  It would be pretty easy to fix if needed.
        if (nSegments ~= 1)
            error('Code is not currently set up to handle more than one attention segment per trial. See comments in code about this.');
        end
        
        % Need the attention event and attention margin durations to be integer multiples of the frame time.  Enforce that here.
        actualAttentionEventDuration = block(trial).modulationData.params.timeStep*ceil((1/block(trial).modulationData.params.timeStep)*protocolParams.attentionEventDuration);
        actualAttentionMarginDuration = block(trial).modulationData.params.timeStep*ceil((1/block(trial).modulationData.params.timeStep)*protocolParams.attentionMarginDuration);
        
        % Some checks that attention parameters are consistent, after adjustment just above.
        if (actualAttentionEventDuration >= actualAttentionMarginDuration)
            error('Attention event duration must be shorter than attention margin duration');
        end
        if (segmentDuration < 2*actualAttentionMarginDuration)
            error('Segment duration is less than twice attentionMarginDuration');
        end
        
        % Iterate over segments setting up an attention event in each one or not, according to a random choice.
        for s = 1:nSegments
            % Define the beginning and end of each segment within the trial as in index into the starts/stops arrays
            % relative to the start of the segment.
            theStartSegmentIndex = (1/block(trial).modulationData.params.timeStep)*protocolParams.attentionSegmentDuration*(s-1)+1;
            theStopSegmentIndex = (1/block(trial).modulationData.params.timeStep)*protocolParams.attentionSegmentDuration*s;
            if (theStartSegmentIndex >= theStopSegmentIndex)
                error('Logic error in defining segment indices for attention event');
            end
            
            % Flip a coin to decide whether we'll have a blank event or not.
            % If yes, then define what the start and stop indices are for this event in this segment
            theCoinFlip = binornd(1, protocolParams.attentionEventProb);
            if theCoinFlip
                % Choose at random which allowable indices within the segments get dimmed.
                theStartBlankIndex = randi([theStartSegmentIndex+(1/block(trial).modulationData.params.timeStep)*actualAttentionMarginDuration theStopSegmentIndex-(1/block(trial).modulationData.params.timeStep)*actualAttentionMarginDuration]);
                theStopBlankIndex = theStartBlankIndex+(1/block(trial).modulationData.params.timeStep)*actualAttentionEventDuration-1;
                
                % Blank out the starts/stops for the trial so that the stimulus gets quite dim during the
                % attention event.
                block(trial).modulationData.modulation.starts(theStartBlankIndex:theStopBlankIndex,:) = 0;
                block(trial).modulationData.modulation.stops(theStartBlankIndex:theStopBlankIndex,:) = 1;
                
                % Say when the attention event was within the segment
                block(trial).attentionTask.segmentFlag(s) = 1;
                block(trial).attentionTask.theStartBlankIndex(s) = theStartBlankIndex;
                block(trial).attentionTask.theStopBlankIndex(s) = theStopBlankIndex;
            else
                % Say there was no attention event
                block(trial).attentionTask.segmentFlag(s) = 0;
                block(trial).attentionTask.theStartBlankIndex(s) = -1;
                block(trial).attentionTask.theStopBlankIndex(s) = -1;
            end         
        end
    end
    
 
end
   fprintf('Done\n');
end



