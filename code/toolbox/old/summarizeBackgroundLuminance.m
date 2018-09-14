function summarizeBackgroundLuminance(varargin)

p = inputParser; p.KeepUnmatched = true;
p.addParameter('stimulusType','LightFlux',@ischar);

% Parse and check the parameters
p.parse(varargin{:});


% find the relevant data
%% first the screening subjects
dataBasePath = getpref('melSquintAnalysis','melaDataPath');


screeningBasePath = fullfile(dataBasePath, 'Experiments', 'OLApproach_Squint', 'Screening', 'DataFiles');

screeningSubjectsList = dir(fullfile(screeningBasePath, 'MELA*'));

for ss = 1:length(screeningSubjectsList)
    screeningSubjects{ss} = screeningSubjectsList(ss).name;
end

for ss = 1:length(screeningSubjects)
    sessionIDFull = dir(fullfile(screeningBasePath, screeningSubjects{ss}, '*_session_*'));
    sessionIDFull = sessionIDFull.name;
    date = strsplit(sessionIDFull, '_');
    date = date{1};
    
    load(fullfile(screeningBasePath, '..', 'DirectionObjects', screeningSubjects{ss}, sessionIDFull, [p.Results.stimulusType, 'Direction.mat']));
    screeningSessions(1,ss) = datenum(date, 'yyyy-mm-dd');
    
    if length(LightFluxDirection.describe.validation)
        for vv = 1:5
            luminanceValues(vv) = LightFluxDirection.describe.validation(vv).luminanceActual(1);
        end
    else
        for vv = 6:10
            luminanceValues(vv) = LightFluxDirection.describe.validation(vv).luminanceActual(1);
        end
    end
    screeningSessions(2,ss) = median(luminanceValues);
    
    
end

%% now the SquintToPulse subjects
dataBasePath = getpref('melSquintAnalysis','melaDataPath');


squintToPulseBasePath = fullfile(dataBasePath, 'Experiments', 'OLApproach_Squint', 'SquintToPulse', 'DataFiles');

squintToPulseSubjectsList = dir(fullfile(squintToPulseBasePath, 'MELA*'));

for ss = 1:length(squintToPulseSubjectsList)
    squintToPulseSubjects{ss} = squintToPulseSubjectsList(ss).name;
end

counter = 1;
for ss = 1:length(squintToPulseSubjects)
    
    potentialSessions = dir(fullfile(squintToPulseBasePath, squintToPulseSubjects{ss}, '*session*'));
    potentialNumberOfSessions = length(potentialSessions);
    
    sessions = [];
    for session = 1:potentialNumberOfSessions
        acquisitions = [];
        for aa = 1:6
            trials = [];
            for tt = 1:10
                if exist(fullfile(squintToPulseBasePath, squintToPulseSubjects{ss}, potentialSessions(session).name, sprintf('videoFiles_acquisition_%02d', aa), sprintf('trial_%03d.mp4', tt)), 'file')
                    trials = [trials, tt];
                end
            end
            if isequal(trials, 1:10)
                acquisitions = [acquisitions, aa];
            end
        end
        if isequal(acquisitions, 1:6)
            sessions = [sessions, session];
        end
    end
    
    sessionIDs = [];
    for session = sessions
        potentialSessions = dir(fullfile(squintToPulseBasePath, squintToPulseSubjects{ss}, sprintf('*session_%d*', session)));
        % in the event of more than one entry for a given session (which would
        % happen if something weird happened with a session and it was
        % restarted on a different day), it'll grab the later dated session,
        % which should always be the one we want
        for ii = 1:length(potentialSessions)
            if ~strcmp(potentialSessions(ii).name(1), 'x')
                sessionIDs{session} = potentialSessions(ii).name;
            end
        end
    end
    
    for session = sessions
        sessionIDFull = sessionIDs{session}
        date = strsplit(sessionIDFull, '_');
        date = date{1};
        
        load(fullfile(squintToPulseBasePath, '..', 'DirectionObjects', squintToPulseSubjects{ss}, sessionIDFull, [p.Results.stimulusType, 'Direction.mat']));
        squintToPulseSessions(1,counter) = datenum(date, 'yyyy-mm-dd');
        
        if length(LightFluxDirection.describe.validation)
            for vv = 1:5
                luminanceValues(vv) = LightFluxDirection.describe.validation(vv).luminanceActual(1);
            end
        else
            for vv = 6:15
                luminanceValues(vv) = LightFluxDirection.describe.validation(vv).luminanceActual(1);
            end
        end
        squintToPulseSessions(2,counter) = median(luminanceValues);
        counter = counter + 1;
    end
    
    
end


end