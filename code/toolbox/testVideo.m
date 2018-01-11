function testVideo(protocolParams)

cameraTurnOnCommand = '/Applications/VLC\ 2.app/Contents/MacOS/VLC qtcapture://0xfa13300005a39230 &';
[recordedErrorFlag, consoleOutput] = system(cameraTurnOnCommand);
commandwindow;
fprintf('- Setup the IR camera. Press <strong>Enter</strong> when complete and ready to move on.\n');
input('');
cameraTurnOffCommand = 'osascript -e ''quit app "VLC"''';
[recordedErrorFlag, consoleOutput] = system(cameraTurnOffCommand);

end