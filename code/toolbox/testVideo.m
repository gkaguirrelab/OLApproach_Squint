function testVideo(protocolParams)

cameraTurnOnCommand = '/Applications/VLC\ 2.app/Contents/MacOS/VLC qtcapture://0xfa13300005a39230 &';
[recordedErrorFlag, consoleOutput] = system(cameraTurnOnCommand);
commandwindow;
fprintf('- Setup the IR camera. Press <strong>Enter</strong> when complete and ready to move on.\n');
input('');
cameraTurnOffCommand = 'osascript -e ''quit app "VLC"''';
[recordedErrorFlag, consoleOutput] = system(cameraTurnOffCommand);


videoRecordSystemCommandStem='ffmpeg -hide_banner -video_size 1280x720 -framerate 60.000240 -f avfoundation -i "0" -c:v mpeg4 -q:v 1';


% make the folder in which to save calibration
% make a good guess of the which subject we're working with
[ subjectID, sessionNumber ] = findMostRecentSession(protocolParams);
subject = GetWithDefault('>> Enter <strong>observer name</strong>', subjectID);
sessionName = GetWithDefault('>> Enter <strong>session number</strong>:', sessionNumber);




todayDate = datestr(now, 'yyyy-mm-dd');
outDir = fullfile(getpref(protocolParams.protocol, 'DataFilesBasePath'), subject, todayDate, sessionName, 'pupilCalibration');
if ~exist(outDir)
    mkdir(outDir); 
end

calibrationDoneFlag = false;
counter = 1;
    while ~calibrationDoneFlag
        micCheckChoice = GetWithDefault('>> Run pupil calibration?? [y/n]', 'y');
        switch micCheckChoice
            case 'y'
                pupilVideoSaveDirectoryPath = outDir;
                duration = 60;
                videoOutFile = fullfile(pupilVideoSaveDirectoryPath, sprintf('calibration_%03d_%s.avi',counter, subject)); 
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
                
            case 'n'
                calibrationDoneFlag = true;
                
            otherwise
        end
    end

end