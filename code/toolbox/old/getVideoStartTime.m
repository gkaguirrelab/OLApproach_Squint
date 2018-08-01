

for trial = 1:10
consoleOutput = strsplit(responseStruct.data(trial).pupil.consoleOutput, 'start: ');
startTimeFromConsoleOutput = strsplit(consoleOutput{2}, ',');
startTimeFromConsoleOutput = str2num(startTimeFromConsoleOutput{1});

startTimeFromUDPCommand = responseStruct.events(trial).tRecordingStart;
stopTimeFromUDPCommand = responseStruct.events(trial).tRecordingEnd;

startTimeFromClock = responseStruct.events(trial).tRecordingStartClock;
startTimeFromClock = startTimeFromClock(5)*60 + startTimeFromClock(6);
stopTimeFromClock = responseStruct.events(trial).tRecordingEndClock;
stopTimeFromClock = stopTimeFromClock(5)*60 + stopTimeFromClock(6);


delay = startTimeFromConsoleOutput - startTimeFromUDPCommand;
delayPooled(trial) = delay;
commandLengthPooled(trial) = stopTimeFromUDPCommand - startTimeFromUDPCommand 
commandLengthPooledClock(trial) = stopTimeFromClock - startTimeFromClock

end

meanDelay = mean(delayPooled)
meanCommandLengthMGL = mean(commandLengthPooled)
meanCommandLengthClock = mean(commandLengthPooledClock)
