function [ subjectID, sessionNumber, acquisitionNumber, experimentNumber ] = findMostRecentSession(protocolParams)
% Guess which was the most recent session that was part of the OLApproach_Squint experiment.
%
% Syntax:
%  [ subjectID, sessionNumber, acquisitionNumber ] = findMostRecentSession(protocolParams)

% Description:
%   This function will search through Dropbox and find the SessionRecord
%   that was most recently changed. The session corresponding to this
%   SessionRecord is assumed to be the most recent session. This function
%   is primarily used as a way to prevent manually entering session
%   information across the three experimental computers. The session
%   information is entered into the base computer once, then the other two
%   computers can use this function to determine which session was just
%   started.

% Inputs:
%   protocolParams        - A struct that defines some basic information
%                           about the expereiment. The only field that
%                           matters for this function is the
%                           protocolParams.protocol field, which tells this
%                           function whether we're looking for a
%                           'Screening' or a 'SquintToPulse' session (i.e.
%                           the contents of protocolParams.protocol are
%                           expected to be either 'SquintToPulse', or
%                           'Screening').
%
% Outputs:
%   subjectID             - A string of the subjectID corresponding to 
%                           the most recent session.
%   sessionNumber         - A string corresponding to the sessionNumber
%                           (i.e. session_1) of the most recent session
%   acquisitionNumber     - A number corresponding to how many acquisitions
%                           have already been completed as part of the most
%                           recent session


% find subject
dataFilesDir = getpref(protocolParams.protocol, 'DataFilesBasePath');
dirContent = dir(fullfile(dataFilesDir, '..', 'SessionRecords'));
dirContent = dirContent(~ismember({dirContent.name},{'.','..', '.DS_Store'}));
[value, index] = max([dirContent(:).datenum]);
subjectID = dirContent(index).name;

% get today's date
todayDate = datestr(now, 'yyyy-mm-dd');

% find experimentName
if strcmp(protocolParams.protocol, 'Deuteranopes')
    experimentDir = fullfile(dataFilesDir, '..', 'DirectionObjects', subjectID);
    experimentDirContent = dir(experimentDir);
    experimentDirContent = experimentDirContent(~ismember({experimentDirContent.name}, {'.','..', '.DS_Store'}));
    [value, index] = max([experimentDirContent(:).datenum]);
    if length(experimentDirContent) == 0
        experimentNumber = 'experiment_1';
    else
        experimentNumber = experimentDirContent(index).name;
    end
else
    experimentNumber = [];
    
end

% find session
sessionDir = fullfile(dataFilesDir, '..', 'SessionRecords', subjectID, todayDate);
sessionDirContent = dir(sessionDir);
sessionDirContent = sessionDirContent(~ismember({sessionDirContent.name}, {'.','..', '.DS_Store'}));
[value, index] = max([sessionDirContent(:).datenum]);
if length(sessionDirContent) == 0
    sessionNumber = 'session_1';
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