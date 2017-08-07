function [keyEvents, t, counter] = TrialSequenceMROLFlicker(ol, block, trial, frameDurationSecs, numIterations)
%%TrialSequenceMROLFlicker  Flickers the OneLight.
%
% This is the function that sends the starts and stops to the OL
%
% Syntax:
% keyPress = ModulationTrialSequenceFlickerStartsStops(trial, frameDurationSecs, numIterations)
%
% Description:
% Flickers the OneLight using the passed stops matrix until a key is
% pressed or the number of iterations is reached.
%
% Input:
% ol (OneLight) - The OneLight object. 
% stops (1024xN) - The normalized [0,1] mirror stops to loop through.
% frameDurationSecs (scalar) - The duration to hold each setting until the
%     next one is loaded.
% numIterations (scalar) - The number of iterations to loop through the
%     stops.  Passing Inf causes the function to loop forever.
%
% Output:
% keyPress (char|empty) - If in continuous mode, the key the user pressed
%     to end the script.  In regular mode, this will always be empty.
%
% WE SHOULD GET OLFLicker TO RETURN keyEvents, t, counter INSTEAD OF USE
% THIS NEEDS TO BE MODIFIED TO WORK AS IS 
%
% I WOULD LIKE TO WORK WITH DB ON THIS TO FIGURE OUT HOW REDUNDANT THIS IS 
%

%tic;
%starts = block(trial).data.starts';
%stops = block(trial).data.stops';

%keyPress = [];

% Flag whether we're checking the keyboard during the flicker loop.
%checkKB = isinf(numIterations);

% Counters to keep track of which of the stops to display and which
% iteration we're on.
iterationCount = 0;
setCount = 0;

numstops = size(block(trial).modulationData.modulation.starts, 1);

t = zeros(1, numstops);
counter = zeros(1, numstops);
i = 0;

% This is the time of the stops change.  It gets updated everytime
% we apply new mirror stops.
mileStone = mglGetSecs + frameDurationSecs;


keyEvents = [];

while iterationCount < numIterations
    if mglGetSecs >= mileStone;
        i = i + 1;
        
        % Update the time of our next switch.
        mileStone = mileStone + frameDurationSecs;
        
        % Update our stops counter.
        setCount = mod(setCount + 1, numstops);
        
        % If we've reached the end of the stops list, iterate the
        % counter that keeps track of how many times we've gone through
        % the list.
        if setCount == 0
            iterationCount = iterationCount + 1;
            setCount = numstops;
        end
        
        % Send over the new stops.
        t(i) = mglGetSecs;
        counter(i) = setCount;
        ol.setMirrors(block(trial).modulationData.modulation.starts(setCount,:), block(trial).modulationData.modulation.stops(setCount,:));
    end
    
end

keyEvents = mglListener('getAllKeyEvents');
end