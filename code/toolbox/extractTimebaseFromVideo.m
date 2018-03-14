function [ timebase ] = extractTimebaseFromVideo(pathToVideo)

% This function extracts the timestamp of each frame captured in the input
% pupil video. The function uses an ffmpeg command (ffprobe) to display
% information about the given video. This input is then parsed to grab the
% timing information, and this timing information is stored in the output
% variable timebase

% Inputs:
%   - pathToVideo: a string that defines the complete path to the video
%   file

% Outputs:
%   - timebase: a vector where each item is the time at which the index
%   frame was captured

% ffmpeg command to dump out the video information
[ status, consoleOutput] = system(['ffprobe -sexagesimal -show_packets -of compact -i "', pathToVideo , '"']);

% columns are organized by '|', so split by this so we can look through
% each item
splitConsoleOutput = strsplit(consoleOutput, '|');

% find the indices that begin with 'pts_time', which are the items that
% contain the time stamp information
index = find(contains(splitConsoleOutput, 'pts_time'));

for ii = 1:length(index)
    
    % grab the part after the equal sign (the time)
    timepoint = strsplit(splitConsoleOutput{index(ii)}, '=');
    
    % split by ':' so we don't have to worry about processing time and time
    % formats
    timepoint = strsplit(timepoint{2}, ':');
    
    % grab the 3rd item of the split, which corresponds to the seconds
    % place
    timepoint = timepoint(3);
    
    % convert that string into a number
    timebase(ii) = str2num(timepoint{1});
end

end