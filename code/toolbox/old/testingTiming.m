videoRecordCommand = 'ffmpeg -hide_banner -video_size 1280x720 -pix_fmt uyvy422 -framerate 60.000240 -f avfoundation -i "0" -c:v mpeg4 -q:v 1 -t 17 "/Users/melanopsin/Dropbox (Aguirre-Brainard Lab)/MELA_data/Experiments/OLApproach_Squint/SquintToPulse/DataFiles/HERO_cameraCheck/2018-02-07/session_1/videoFiles_acquisition_01/trial_004.avi"';
%videoRecordCommand = 'ffmpeg -hide_banner -video_size 1280x720 -framerate 60.000240 -f avfoundation -use_wallclock_as_timestamps 0 -i "0" -c:v mpeg4 -q:v 1 -t 17 "/Users/melanopsin/Dropbox (Aguirre-Brainard Lab)/MELA_data/Experiments/OLApproach_Squint/SquintToPulse/DataFiles/HERO_cameraCheck/2018-02-07/session_1/videoFiles_acquisition_01/trial_004.avi"';
%'ffmpeg -hide_banner -video_size 1280x720 -pix_fmt uyvy422 -framerate 60.000240 -f avfoundation -i "0" -filter_complex "drawtext=fontfile=/Library/Fonts/Arial.ttf:text='timestamp: \: %{pts\:gmtime\:0/:H %M %S}': x=5: y=5: fontsize=16:fontcolor=yellow@0.9: box=1: boxcolor=blue@0.6"-c:v mpeg4 -q:v 1 -t 17  "/Users/melanopsin/Dropbox (Aguirre-Brainard Lab)/MELA_data/Experiments/OLApproach_Squint/SquintToPulse/DataFiles/HERO_cameraCheck/2018-02-07/session_1/videoFiles_acquisition_01/trial_004.avi"'
videoRecordCommand = 'ffmpeg -hide_banner -video_size 1280x720 -framerate 60.000240 -f avfoundation -i "0" -c:v mpeg4 -q:v 1 -t 17 "/Users/melanopsin/Dropbox (Aguirre-Brainard Lab)/MELA_data/Experiments/OLApproach_Squint/SquintToPulse/DataFiles/HERO_cameraCheck/2018-02-07/session_1/videoFiles_acquisition_01/trial_004.avi"';


timeIn = mglGetSecs; 
if any(cellfun(@(x) sum(strcmp(x,'pupil')), protocolParams.myActions))
[error, output] = system(videoRecordCommand); 

consoleOutput = strsplit(output, 'start: ');
startTimeFromConsoleOutput = strsplit(consoleOutput{2}, ',');
startTimeFromConsoleOutput = str2num(startTimeFromConsoleOutput{1});
end
timeOut = mglGetSecs;
delay = startTimeFromConsoleOutput - timeIn
interval = timeOut - timeIn

