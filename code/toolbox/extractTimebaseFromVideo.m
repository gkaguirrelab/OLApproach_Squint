function [ timebase ] = extractTimebaseFromVideo(pathToVideo)

[ status, consoleOutput] = system(['ffprobe -sexagesimal -show_packets -of compact -i "', pathToVideo , '"']);
splitConsoleOutput = strsplit(consoleOutput, '|');
index = find(contains(splitConsoleOutput, 'pts_time'));

for ii = 1:length(index)
    timepoint = strsplit(splitConsoleOutput{index(ii)}, '=');
    timepoint = strsplit(timepoint{2}, ':');
    timepoint = timepoint(3);
    timebase(ii) = str2num(timepoint{1});
end

end