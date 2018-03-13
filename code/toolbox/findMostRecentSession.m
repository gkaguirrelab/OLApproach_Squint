function [ subjectID, sessionNumber, acquisitionNumber ] = findMostRecentSession(protocolParams)

% find subject
dataFilesDir = getpref(protocolParams.protocol, 'DataFilesBasePath');
dirContent = dir(fullfile(dataFilesDir, '..', 'SessionRecords'));
dirContent = dirContent(~ismember({dirContent.name},{'.','..', '.DS_Store'}));
[value, index] = max([dirContent(:).datenum]);
subjectID = dirContent(index).name;

% get today's date
todayDate = datestr(now, 'yyyy-mm-dd');

% find session
sessionDir = fullfile(dataFilesDir, '..', 'SessionRecords', subjectID, todayDate);
sessionDirContent = dir(sessionDir);
sessionDirContent = sessionDirContent(~ismember({sessionDirContent.name}, {'.','..', '.DS_Store'}));
[value, index] = max([sessionDirContent(:).datenum]);
if length(sessionDirContent) == 0
    sessionNumber = [];
else
    sessionNumber = sessionDirContent(index).name;
end

% find most recent acquisition
dataDir = fullfile(dataFilesDir, subjectID, todayDate, sessionNumber);
dataDirContent = dir(fullfile(dataDir, '*.mat'));
if length(dataDirContent) == 0
    acquisitionNumber = 0;
else
    [value, index] = max([dataDirContent(:).datenum]);
    acquisitionFile = dataDirContent(index).name;
    splits = strsplit(acquisitionFile, 'acquisition');
    acquisitionNumber = strsplit(splits{2}, '_');
    acquisitionNumber = str2num(acquisitionNumber{1});
end


end