function dropBoxSyncingStatus = pauseUnpauseDropbox(varargin)
% Uses a system command to resume dropBox syncing via a shell script
%
% Syntax: 
%
%       dropBoxSyncingStatus = pauseUnpauseDropbox('command', '--pause');
%
% Optional key-value pair inputs:
%   command                 - A string that must read '--pause' or '--resume'.
%                             Refers to whether we're pausing or resuming Dropbox
%                             activity.
% Output:
%   dropBoxSyncingStatus    - A logical. If 0, Dropbox is functional (i.e.
%                             not paused). if O, then dropbox is paused, if
%                             NaN, then unable to determine

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

