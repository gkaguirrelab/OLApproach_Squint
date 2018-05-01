protocolParams.protocol = 'SquintToPulse';
protocolParams.videoRecordSystemCommandStem=['ffmpeg -hide_banner -video_size 1280x720 -pix_fmt uyvy422 -vsync 0 -framerate 60.000240 -f avfoundation -i "0" -c:v mpeg4 -q:v 1'];
pupilVideoSaveDirectoryPath = fullfile(getpref(protocolParams.protocol, 'DataFilesBasePath'), 'cameraDebugging');

potentialVideoFiles = dir(fullfile(pupilVideoSaveDirectoryPath, 'sample*'));

if length(potentialVideoFiles) == 0
    counter = 1;
else
    
    counter = 1 + length(potentialVideoFiles);
end

if ~exist(pupilVideoSaveDirectoryPath,'dir')
    mkdir(pupilVideoSaveDirectoryPath);
end


videoOutFile = fullfile(pupilVideoSaveDirectoryPath, sprintf('sample_vsync0_%03d.mp4',counter));
videoRecordCommand = [protocolParams.videoRecordSystemCommandStem ' -t 17' ' "' videoOutFile '"'];
[recordErrorFlag,consoleOutput]=system(videoRecordCommand);
