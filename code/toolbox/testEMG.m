function [plotFig] = testEMG(protocolParams)
% A quick function to test if the EMG is up and running
%
% Syntax:
%  [plotFig] = testEMG(protocolParams)

% Description:
%   This function records EMG activity over a 5 second window, prompting
%   the operator when that window begins on screen. This function is
%   intended to be used as part of a pre-flight routine just prior to
%   beginning an experiment where we want to make sure all of our equipment
%   is working properly.

% Inputs:
%   protocolParams        - A struct that defines the basics of the
%                           experiment. I don't believe it actually does
%                           anything in this routine.
% Outputs:
%   plotFig               - A figure handle, used to easily clean up after
%                           running this function or potentially running it
%                           multiple times.

tic;
emgOutput = SquintRecordEMG(...
                'recordingDurationSecs', 5, ...
                'simulate', false, ...
                'verbose', true);

            
plotFig = figure('name', 'plotFig');
subplot(1,2,1)
plot(emgOutput.timebase, emgOutput.response(1,:));
xlabel('Time (s)')
ylabel('Voltage (mV)')
title('Right Leads')

subplot(1,2,2)
plot(emgOutput.timebase, emgOutput.response(2,:));
xlabel('Time (s)')
ylabel('Voltage (mV)')
title('Left Leads')
            
end