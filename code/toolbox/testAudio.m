function [ plotFig ] = testAudio(protocolParams)
% This code functions to test the audio equipment. The idea is before we
% actually run this experiment, this is one piece of our "pre-flight" code
% to make sure all of the hardware is up and running.

% The routine uses the parameters of the actual listening window used in
% the experiment, including the beep and boop at the start and end of the
% trial. Subjects should be prompted to speak during the window; the
% recording will be played back to ensure it's satisfactory and a plot of
% the audio will also be displayed.

% Inputs:
%   - protocolParams: a structure containing all of the experiment
%   information. It provides information about the
%   trialResponseWindowTimeSec as well as the audioRecordObjCommand (in
%   addition to all of the other protocolParams used for different aspects
%   of the experiment).

% Outputs:
%   - plotFig: outputting the figure handle so it can be easily closed
%   after the audio check is done



% setup some parameters -- only used for debugging on a different computer
% with differnet audio recording equipment
%protocolParams.trialResponseWindowTimeSec = 4;
%protocolParams.audioRecordObjCommand='audiorecorder(16000,8,1,3)'; %
%correct ID (3) for the stimulus computer
%protocolParams.audioRecordObjCommand='audiorecorder(16000,8,1,0)'; % hopefully the correct ID (0) for my bluetooth headphones for troulbe shooting


audioRecObj = eval(protocolParams.audioRecordObjCommand);
record(audioRecObj,protocolParams.trialResponseWindowTimeSec);

% make beep
%t = linspace(0, 1, 2400);
%y = sin(160*2*pi*t)*0.5;
%sound(y, 16000);
% say "Rating"
speakRateDefault = getpref(protocolParams.approach, 'SpeakRateDefault');
Speak('Rating', [], speakRateDefault);

% pause for the 4 second recording window
mglWaitSecs(protocolParams.trialResponseWindowTimeSec);

% make boop
t = linspace(0, 1, 4800);
y = sin(160*2*pi*t)*0.5;
sound(y, 16000);

% Wait for the post-response time tone to play
mglWaitSecs(4000/16000 * 2);

% grab audio data
audioOutput = getaudiodata(audioRecObj);

% plot audio trace
plotFig = figure('name', 'plotFig');
plot(0:4/64000:4-1/64000, audioOutput)
ylabel('Amplitude')
xlabel('Time (s)')
title('Audio Output')

% playback audio
sound(audioOutput, 16000);
