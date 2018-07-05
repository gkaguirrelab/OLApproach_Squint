function [ protocolParams ] = getDefaultParams(varargin)


%% parse inputs
p = inputParser; p.KeepUnmatched = true;

p.addParameter('calibrationType','BoxBShortLiquidLightGuideDEyePiece1_ND04',@ischar);
p.addParameter('nTrials',10,@isnumeric);
p.addParameter('computerName','trashCan',@ischar);
p.addParameter('protocol','SquintToPulse',@ischar);



p.parse(varargin{:});


%% setup experiment type, either screening or the real deal
protocolParams.approach = 'OLApproach_Squint';
if strcmp(p.Results.protocol, 'Screening')
    protocolParams.protocol = 'Screening';
    protocolParams.protocolOutputName = 'Screening';
elseif strcmp(p.Results.protocol, 'SquintToPulse')
    protocolParams.protocol = 'SquintToPulse';
    protocolParams.protocolOutputName = 'StP';
end

protocolParams.emailRecipient = 'jryan@mail.med.upenn.edu';
protocolParams.verbose = true;
protocolParams.setup = false;
protocolParams.resume = true;

%% control simulation behavior
% if we're using

info = GetComputerInfo;
if strcmp(info.userShortName, 'harrisonmcadams')
    % if we're on the trashcan, we've got to simulate everything
    protocolParams.simulate.oneLight = true;
    protocolParams.simulate.radiometer = true;
    protocolParams.simulate.microphone = true;
    protocolParams.simulate.speaker = true;
    protocolParams.simulate.emg = true;
    protocolParams.simulate.pupil = true;
    protocolParams.simulate.udp = true;
    protocolParams.simulate.observer = true;
    protocolParams.simulate.operator = true;
    protocolParams.simulate.makePlots = true;
elseif strcmp(protocolParams.protocol, 'Screening')
    % if we're screening, we can simulate EMG
    protocolParams.simulate.oneLight = false;
    protocolParams.simulate.radiometer = false;
    protocolParams.simulate.microphone = true;
    protocolParams.simulate.speaker = false;
    protocolParams.simulate.emg = true;
    protocolParams.simulate.pupil = false;
    protocolParams.simulate.udp = false;
    protocolParams.simulate.observer = false;
    protocolParams.simulate.operator = false;
    protocolParams.simulate.makePlots = true;
elseif strcmp(protocolParams.protocol, 'SquintToPulse')
    % for the real experiment, we're not simulating anything
    protocolParams.simulate.oneLight = false;
    protocolParams.simulate.radiometer = false;
    protocolParams.simulate.microphone = false;
    protocolParams.simulate.speaker = false;
    protocolParams.simulate.emg = false;
    protocolParams.simulate.pupil = false;
    protocolParams.simulate.udp = false;
    protocolParams.simulate.observer = false;
    protocolParams.simulate.operator = false;
    protocolParams.simulate.makePlots = true;
    
end

% define local dictionaries
protocolParams.directionsDictionary = 'OLDirectionParamsDictionary_Squint';
protocolParams.backgroundsDictionary = 'OLBackgroundParamsDictionary_Squint';

% define the identities of the base computer (which oversees the
% experiment and controls the OneLight) and the satellite computers that
% handle EMG and pupil recording
%protocolParams.hostNames = {'gka06', 'gka33', 'monkfish'};
protocolParams.hostNames = {'modv-ve507-0663', 'gka33', 'monkfish'}; % fugu

%protocolParams.hostIPs = {'128.91.59.227', '128.91.59.228', '128.91.59.157'};
protocolParams.hostIPs = {'130.91.151.104', '128.91.59.228', '128.91.59.157'}; % fugu

protocolParams.hostRoles = {'base', 'satellite', 'satellite'};
protocolParams.hostActions = {{'operator','observer','oneLight'}, 'emg', 'pupil'};

% provide the basic command for video acquisition
% To determine which device to record from, issue thecommand
%       ffmpeg -f avfoundation -list_devices true -i ""
% in the terminal. Identify which device number we want, and place that in
% the quotes after the -i in the command stem below.
% GKA NOTE: do we also need the argument -pixel_format uyvy422  ?
protocolParams.videoRecordSystemCommandStem=['ffmpeg -hide_banner -video_size 1280x720 -pix_fmt uyvy422 -framerate 60.000240 -f avfoundation -i "1" -c:v mpeg4 -q:v 1'];
protocolParams.audioRecordObjCommand='audiorecorder(16000,8,1,2)';

% Establish myRole and myActions
if protocolParams.simulate.udp
    % If we are simulating the UDP connection stream, then we will operate
    % as the base and simulate the satellite component when needed.
    protocolParams.myRoles = {'base','satellite','satellite'};
    % If we are simulating the UDP connection stream, then we will execute
    % all actions in this routine.
    protocolParams.myActions = {{'operator','observer','oneLight'}, 'pupil', 'emg'};
    
else
    % Get local computer name
    localHostName = UDPBaseSatelliteCommunicator.getLocalHostName();
    % Find which hostName is contained within my computer name
    idxWhichHostAmI = find(cellfun(@(x) contains(localHostName, x), protocolParams.hostNames));
    if isempty(idxWhichHostAmI)
        error(['My local host name (' localHostName ') does not match an available host name']);
    end
    % Assign me the role corresponding to my host name
    protocolParams.myRoles = protocolParams.hostRoles{idxWhichHostAmI};
    if ~iscell(protocolParams.myRoles)
        protocolParams.myRoles={protocolParams.myRoles};
    end
    % Assign me the actions corresponding to my host name
    protocolParams.myActions = protocolParams.hostActions{idxWhichHostAmI};
    if ~iscell(protocolParams.myActions)
        protocolParams.myActions={protocolParams.myActions};
    end
end

% Field size and pupil size.
%
% These are used to construct photoreceptors for validation for directions
% (e.g. light flux) where they are not available in the direction file.
% They are checked for consistency with direction parameters that specify
% these fields in OLAnalyzeDirectionCorrectedPrimaries.
protocolParams.fieldSizeDegrees = 27.5;
protocolParams.pupilDiameterMm = 6;

%% Trial timing parameters.
%
% A trial is composed of the following elements:
% - [trialMinJitterTimeSec, trialMaxJitterTimeSec] defines the bounds on a
%   uniform random distribution of time spent on the background prior to
%   trial initiation. A key property of the jitter period is that
%   physiologic data are not recorded during this interval. An audio alert
%   plays prior to the start of the jitter time.
% - trialBackgroundTimeSec - presentation of the background prior to the
%   stimulus. Physiologic recording begins with the onset of the
%   background period.
% - stimulusDuration - duration of the modulation itself. This is defined
%   by the stimulus dictionary
% - trialISITimeSec - duration of presentation of the background after the
%   stimulus. Physiologic recording ends at the end of the ISI time.
% - trialResponseWindowTimeSec - duration of a response window during which
%   the subject can make verbal or keypress responses. An audio alert plays
%   prior to the start of the response window.
%
protocolParams.trialMinJitterTimeSec = 0.5;
protocolParams.trialMaxJitterTimeSec = 1.5;
protocolParams.trialBackgroundTimeSec = 1;
protocolParams.trialISITimeSec = 12;
protocolParams.trialJitterRecordingDurationSec = 0.5;


% for screenig we eliminate the verbal response window
if strcmp(protocolParams.protocol, 'Screening')
    protocolParams.trialResponseWindowTimeSec = 0;
elseif strcmp(protocolParams.protocol, 'SquintToPulse')
    protocolParams.trialResponseWindowTimeSec = 4;
end


% note that nTrials is directly related to modulation data, in the sense
% that they have to have the same dimensions. by explicitly using a key
% value pair, we can be clear about how many trials per acquisition we're
% dealing with
protocolParams.nTrials = p.Results.nTrials;


protocolParams.attentionTask = false;


% OneLight parameters
%protocolParams.boxName = 'BoxB';
protocolParams.takeCalStateMeasurements = true;
protocolParams.takeTemperatureMeasurements = false;
protocolParams.calibrationType = p.Results.calibrationType;



% Validation parameters
protocolParams.nValidationsPerDirection = 5;