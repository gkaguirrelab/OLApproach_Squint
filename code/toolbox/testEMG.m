function [plotFig] = testEMG(protocolParams)

emgOutput = SquintRecordEMG(...
                'recordingDurationSecs', 5, ...
                'simulate', false, ...
                'verbose', true);

            
plotFig = figure('name', 'plotFig');
subplot(1,2,1)
plot(emgOutput.timebase, emgOutput.response(1,:));
xlabel('Time (s)')
ylabel('Voltage ***?')
title('*** Leads')

subplot(1,2,2)
plot(emgOutput.timebase, emgOutput.response(1,:));
xlabel('Time (s)')
ylabel('Voltage ***?')
title('*** Leads')
            
end