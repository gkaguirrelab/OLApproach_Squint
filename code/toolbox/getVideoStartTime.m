

for trial = 1:10;
consoleOutput = strsplit(responseStruct.data(trial).pupil.consoleOutput, 'start: ');
startTimeFromConsoleOutput = strsplit(consoleOutput{2}, ',');
startTimeFromConsoleOutput = str2num(startTimeFromConsoleOutput{1});

startTimeFromUDPCommand = responseStruct.events(trial).tRecordingStart;

delay = startTimeFromConsoleOutput - startTimeFromUDPCommand;
delayPooled(trial) = delay;
end

mean(delayPooled)