function protocolParams = testVideo(protocolParams, varargin)
% A function to test the pupil camera as well as run pupil gaze calibration
%
% Syntax:
%   protocolParams = testVideo(protocolParams)

% Description:
%   This function is part of the pre-flight routine to test the various
%   pieces of equipment prior to an experiment. First we just open the
%   camera in VLC, allowing the operator to adjust the camera so it's
%   properly positioned to capture the subject's eye. Then it will prompt
%   the operator to begin pupil calibration, where we'll save a video of a
%   the subject fixated at various positions along the eyepiece for use in
%   constraining scene geometry as part of pupil tracking.

% Inputs:
%   protocolParams        - A struct that defines some basics about the
%                           experiment. The relevant fields include 1)
%                           information about the subject (which will be
%                           manually entered if not originally part of the
%                           struct), 2) the protocol name (which controls
%                           where to save the calibration video, either
%                           'Screening' or 'SquintToPulse'), and 3) the
%                           videoRecordSystemCommandStem (the command to
%                           ffmpeg)
%
% Optional Key-Value Pairs:
%   label                 - A string that modifies the name of the saved
%                           pupil gaze calibration video. Often 'pre' or
%                           'post' to describe if this video was saved
%                           before or after the experiment.
% Outputs:
%   protocolParams        - The inputted protocolParams is potentially
%                           appended with subject information (subjectID,
%                           sessionName, etc.)


%% parse input
p = inputParser;
p.addParameter('label','pre',@ischar);

p.parse(varargin{:});


%% open up IR camera to adjust placement of subject in rig
if strcmp(p.Results.label, 'pre')
    cameraTurnOnCommand = '/Applications/VLC.app/Contents/MacOS/VLC qtcapture://0x1444000005a39230 --qtcapture-width 1280 --qtcapture-height 720 &';
    [recordedErrorFlag, consoleOutput] = system(cameraTurnOnCommand);
    commandwindow;
    fprintf('- Setup the IR camera. Press <strong>Enter</strong> when complete and ready to move on.\n');
    input('');
    cameraTurnOffCommand = 'osascript -e ''quit app "VLC"''';
    [recordedErrorFlag, consoleOutput] = system(cameraTurnOffCommand);
    
    % pre video record command
    videoRecordSystemCommandStem='ffmpeg -hide_banner -video_size 1280x720 -framerate 60.000240 -f avfoundation -i "0" -c:v mpeg4 -q:v 1';
end






%% run the actual pupil calibration
calibrationDoneFlag = false;
counter = 1;
while ~calibrationDoneFlag
    micCheckChoice = GetWithDefault('>> Run pupil calibration?? [y/n]', 'y');
    switch micCheckChoice
        case 'y'
            % if it's the first calibration run, grab the subject
            % information so we know where to save
            if ~isfield(protocolParams, 'observerID') || ~isfield(protocolParams, 'sessionName')
                % make the folder in which to save calibration
                % make a good guess of the which subject we're working with
                [ subjectID, sessionNumber, ~, experimentName ] = findMostRecentSession(protocolParams);
                protocolParams.observerID = GetWithDefault('>> Enter <strong>observer name</strong>', subjectID);
                protocolParams.sessionName = GetWithDefault('>> Enter <strong>session number</strong>:', sessionNumber);
                protocolParams.experimentName = GetWithDefault('>> Enter <strong>experiment number</strong>:', experimentName);

            end
            
            
            todayDate = datestr(now, 'yyyy-mm-dd');
            outDir = fullfile(getpref(protocolParams.protocol, 'DataFilesBasePath'), protocolParams.observerID, protocolParams.experimentName, [todayDate, '_', protocolParams.sessionName], 'pupilCalibration');
            if ~exist(outDir)
                mkdir(outDir);
            end
            
            pupilVideoSaveDirectoryPath = outDir;
            duration = 60;
            videoOutFile = fullfile(pupilVideoSaveDirectoryPath, sprintf('calibration_%03d_%s_%s.mp4',counter, protocolParams.observerID, p.Results.label));
            videoRecordCommand = [protocolParams.videoRecordSystemCommandStem ' -t ' num2str(duration) ' "' videoOutFile '"'];
            [recordErrorFlag,consoleOutput]=system([videoRecordCommand , ' &']);
            % audio routine to guide subject
            Speak('Center');
            pause(2);
            Speak('Up');
            pause(2);
            Speak('Center');
            pause(2);
            Speak('Right');
            pause(2);
            Speak('Center');
            pause(2);
            Speak('Down');
            pause(2);
            Speak('Center');
            pause(2);
            Speak('Left');
            pause(2);
            Speak('Center');
            pause(2);
            Speak('Up');
            pause(2);
            Speak('Center');
            pause(2);
            Speak('Right');
            pause(2);
            Speak('Center');
            pause(2);
            Speak('Down');
            pause(2);
            Speak('Center');
            pause(2);
            Speak('Left');
            pause(2);
            Speak('Center');
            pause(2);
            Speak('Up');
            pause(2);
            Speak('Center');
            pause(2);
            Speak('Right');
            pause(2);
            Speak('Center');
            pause(2);
            Speak('Down');
            pause(2);
            Speak('Center');
            pause(2);
            Speak('Left');
            pause(2);
            
            
            
            counter = counter + 1;
            
            playCommand = ['/Applications/VLC\ 2.app/Contents/MacOS/VLC play ' videoOutFile ' &'];
            [recordErrorFlag,consoleOutput]=system(playCommand);
            
            % enter distance from corneal apex to camera lens:
            distanceFromCornealApexToIRLens = GetWithDefault('>> Enter distance from corneal apex to camera lens', []);
            save(fullfile(outDir, 'distance.mat'), 'distanceFromCornealApexToIRLens');
            
        case 'n'
            calibrationDoneFlag = true;
            
        otherwise
    end
end




end