function [ subjectID, sessionNumber ] = findMostRecentSession(protocolParams)

dataFilesDir = getpref(protocolParams.protocol, 'DataFilesBasePath');
dirContent = dir(fullfile(dataFilesDir, '..', 'SessionRecords'));
dirContent = dirContent(~ismember({dirContent.name},{'.','..', '.DS_Store'}));
[value, index] = max([dirContent(:).datenum]);

subjectID = dirContent(index).name;
todayDate = datestr(now, 'yyyy-mm-dd');

sessionDir = fullfile(dataFilesDir, '..', 'SessionRecords', subjectID, todayDate);
sessionDirContent = dir(sessionDir);
sessionDirContent = sessionDirContent(~ismember({sessionDirContent.name}, {'.','..', '.DS_Store'}));
[value, index] = max([sessionDirContent(:).datenum]);
sessionNumber = sessionDirContent(index).name;

end