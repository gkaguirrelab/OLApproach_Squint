function prepSubject(ol, protocolParams)

%% Prepare equipment and subject

% we're going to be running scratch trials where everything is simulated ex
% except the piece of hardware in question. the idea is that we'll run the
% trial, make sure that the single hardware piece gave appropriate output,
% then move onto the next piece of hardware
scratchProtocolParams = protocolParams;
scratchProtocolParams.setup = true;
scratchProtocolParams.simulate.oneLight = true;
scratchProtocolParams.simulate.microphone = true;
scratchProtocolParams.simulate.speaker = false;
scratchProtocolParams.simulate.emg = true;
scratchProtocolParams.simulate.pupil = true;
scratchProtocolParams.simulate.udp = true;
scratchProtocolParams.simulate.observer = false;
scratchProtocolParams.simulate.operator = false;

% have to specify where to save, here a special setup dir with the normal session dir, rather than the
% traditional session dir where the actual data will go
if any(cellfun(@(x) sum(strcmp(x,'base')),protocolParams.myRoles))
    savePath = fullfile(getpref(scratchProtocolParams.protocol, 'DataFilesBasePath'),scratchProtocolParams.observerID, scratchProtocolParams.todayDate, scratchProtocolParams.sessionName, 'setup');
end


% check IR camera setup first
% note that here we're just opening the camera and displaying the output,
% giving time for the user to adjust the setup so that the pupil is
% properly positioned. That is, unlike the rest of the checks, we're not
% actually running a scratch trial
if any(cellfun(@(x) sum(strcmp(x,'pupil')), protocolParams.myActions))
    cameraTurnOnCommand = '/Applications/VLC\ 2.app/Contents/MacOS/VLC qtcapture://0xfa13300005a39230 &';
    [recordedErrorFlag, consoleOutput] = system(cameraTurnOnCommand);
    commandwindow;
    fprintf('- Setup the IR camera. Press <strong>Enter</strong> when complete and ready to move on.\n');
    input('');
    cameraTurnOffCommand = 'osascript -e ''quit app "VLC"''';
    [recordedErrorFlag, consoleOutput] = system(cameraTurnOffCommand);
end


% Now check on the microphone
scratchProtocolParams.trialTypeOrder = [1];
scratchProtocolParams.nTrials = length(scratchProtocolParams.trialTypeOrder);
% microphone just relies on the base, so only the base needs to get
% involved
if any(cellfun(@(x) sum(strcmp(x,'base')),protocolParams.myRoles))
    % check IR camera status
    commandwindow;
    fprintf('- Checking the microphone. Press <strong>Enter</strong> when ready.\n');
    input('');
    
    
    
    % make scratch trial short and sweet
    scratchProtocolParams.trialMinJitterTimeSec = 0;
    scratchProtocolParams.trialMaxJitterTimeSec = 0;
    scratchProtocolParams.trialBackgroundTimeSec = 0;
    scratchProtocolParams.trialISITimeSec = 0;
    scratchProtocolParams.trialResponseWindowTimeSec = 4;
    scratchProtocolParams.simulate.microphone = false;
    
    toContinue = 'n';
    while toContinue ~= 'y'
        if any(cellfun(@(x) sum(strcmp(x,'base')),protocolParams.myRoles))
            if exist(fullfile(savePath, [scratchProtocolParams.sessionName '_' scratchProtocolParams.protocolOutputName sprintf('_acquisition%02d_base.mat',1)]), 'file');
                delete(fullfile(savePath, [scratchProtocolParams.sessionName '_' scratchProtocolParams.protocolOutputName sprintf('_acquisition%02d_base.mat',1)]));
            end
        end
        
        % run scratch trial
        ApproachEngine(ol,scratchProtocolParams,'acquisitionNumber', 1,'verbose',false);
        
        % show plot of audio results to convince us the mic is working
        if any(cellfun(@(x) sum(strcmp(x,'base')),protocolParams.myRoles))
            data = load(fullfile(savePath, [scratchProtocolParams.sessionName '_' scratchProtocolParams.protocolOutputName sprintf('_acquisition%02d_base.mat',1)]));
            plotFig = figure;
            plot(data.responseStruct.data.audio)
            ylabel('Amplitude')
            xlabel('Time')
            title('Audio Output')
            
            toContinue = GetWithDefault('Does the audio look OK? If yes, setup will continue', 'y');
            
            close(plotFig)
        end
    end
    
    movefile(fullfile(savePath, [scratchProtocolParams.sessionName '_' scratchProtocolParams.protocolOutputName sprintf('_acquisition%02d_base.mat',1)]), fullfile(savePath, [scratchProtocolParams.sessionName '_' scratchProtocolParams.protocolOutputName sprintf('_acquisition%02d_base_audioCheck.mat',1)]));
    
    % now show subjects the range of contrasts to see if any of them make the
    % subject uncomfortable
    scratchProtocolParams.simulate.oneLight = true;
    scratchProtocolParams.simulate.microphone = true;
    scratchProtocolParams.simulate.speaker = false;
    scratchProtocolParams.simulate.emg = true;
    scratchProtocolParams.simulate.pupil = true;
    scratchProtocolParams.simulate.udp = true;
    scratchProtocolParams.simulate.observer = false;
    scratchProtocolParams.simulate.operator = false;
    scratchProtocolParams.trialResponseWindowTimeSec = 0;
    
    contrastValues = {100, 200, 400};
    loopIndex = 1;
    for contrastLevel = [3 2 1]
        
        fprintf('- Now showing %02d%% melanopsin contrast\n', contrastValues{loopIndex});
        scratchProtocolParams.trialTypeOrder = [contrastLevel];
        
        ApproachEngine(ol,scratchProtocolParams,'acquisitionNumber', contrastLevel,'verbose',false);
        if any(cellfun(@(x) sum(strcmp(x,'base')),protocolParams.myRoles))
            movefile(fullfile(savePath, [scratchProtocolParams.sessionName '_' scratchProtocolParams.protocolOutputName sprintf('_acquisition%02d_base.mat',contrastLevel)]), fullfile(savePath, [scratchProtocolParams.sessionName '_' scratchProtocolParams.protocolOutputName sprintf('_acquisition%02d_base_contrastCheck.mat',contrastLevel)]));
        end
        
        loopIndex = loopIndex+1;
    end
end

% now the subject can practice the whole trial procedure

toContinue = 'y';
scratchProtocolParams = protocolParams;
scratchProtocolParams.trialTypeOrder = [3];
scratchProtocolParams.nTrials = length(scratchProtocolParams.trialTypeOrder);
scratchProtocolParams.setup = true;

counter = 1;
while toContinue ~= 'n'
    
    ApproachEngine(ol,scratchProtocolParams,'acquisitionNumber', counter,'verbose',protocolParams.verbose);
    
    % bit of a code issue to work out: we want the option to be able to
    % repeat practice trials as many times as the subject needs. however,
    % it would be great for the decision to repeat/continue to only need to
    % take place via the base computer.
    %if any(cellfun(@(x) sum(strcmp(x,'base')),protocolParams.myRoles))
        toContinue = GetWithDefault('Want another practice trial?', 'y');
        %delete(fullfile(savePath, [scratchProtocolParams.sessionName '_' scratchProtocolParams.protocolOutputName sprintf('_acquisition%02d_base.mat',1)]));
    %end
    counter = counter + 1;
end




end % end function