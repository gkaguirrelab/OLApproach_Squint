function dropBoxSyncingStatus = pauseUnpauseDropbox(varargin)
% Uses a system command to resume dropBox syncing via a shell script
%

p = inputParser;

% Optional display and I/O params
p.addParameter('command','', @(x)(strcmp(x,'--pause') || strcmp(x,'--resume')));

% parse
p.parse(varargin{:})

codeBaseDir = getpref('OLApproach_Squint','CodePath');
pauseUnpauseDropBoxScriptPath = fullfile(codeBaseDir,'toolbox','dropbox-pause-unpause-master','dropbox-pause-unpause.sh');
[status,cmdout] = system([pauseUnpauseDropBoxScriptPath ' ' p.Results.command]);
if status
    error('Error executing dropBox system shell script command');
end
if contains(cmdout,'NORMAL')
    dropBoxSyncingStatus = 1;
    return
end
if contains(cmdout,'PAUSED')
    dropBoxSyncingStatus = 0;
    return
end
dropBoxSyncingStatus = nan;
warning('Unable to determine dropBox syncing status');
end

