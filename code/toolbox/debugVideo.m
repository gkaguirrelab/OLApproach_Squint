protocolParams.protocol = 'SquintToPulse';
protocolParams.videoRecordSystemCommandStem=['ffmpeg -hide_banner -video_size 1280x720 -pix_fmt uyvy422 -framerate 60.000240 -f avfoundation -i "0" -c:v mpeg4 -q:v 1'];
pupilVideoSaveDirectoryPath = fullfile(getpref(protocolParams.protocol, 'DataFilesBasePath'), 'cameraDebugging');

potentialVideoFiles = dir(pupilVideoSaveDirectoryPath, 'sample*');
potentialVideoFiles = potentialVideoFiles.names;

counter = 1 + length(potentialVideoFiles);


videoOutFile = fullfile(pupilVideoSaveDirectoryPath, sprintf('sample_%03d.mp4',counter));
videoRecordCommand = [protocolParams.videoRecordSystemCommandStem ' -t ' num2str(theMessageReceived.data.duration) ' "' videoOutFile '"'];
[recordErrorFlag,consoleOutput]=system(videoRecordCommand);
