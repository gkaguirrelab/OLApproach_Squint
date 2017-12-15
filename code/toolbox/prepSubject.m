function prepSubject(ol, protocolParams)
% This function is intended to prepare the subject for the subsequent
% experiment session. This includes making sure that the various pieces of
% hardware are working, that the subject can tolerate the stimuli, and
% scratch trials so the subject can get used to the trial structure. 

% Each hardware check is performed by the computer that controls that piece
% of hardware. First, the base computer will check the audio. This includes
% running an abbreviated scratch trial with a full "listening" window. The
% subject should be seated in the rig and prompted to say something during
% the "listening" window. After the trial, a plot of the recorded audio
% will be displayed on the base computer. If the operator is satisfied, the
% routine moves onto checking the setup of the IR camera. This action is
% performed by one of the satellites (monkfish/mac mini). Rather than run a
% scratch trial, the routine simply opens the IR camera via the app VLC on the satellite compiuter.
% This allows for the operator to setup the rig such that the subject's
% pupil is properly recorded. The third hardware check will be the check
% the EMG on the other satellite (gka33, the macbook air); this has not yet
% been implemented.

% After the hardware checks, the subjects will be shown three trials of
% increasing melanopsin contrast (100% -> 200% -> 400%). This is meant to
% ensure the subject can tolerate each step in melanopsin contrast. The
% subject is required to prompt the base computer via a button press on the
% controller to proceed to the next trial. This only shows Mel stimuli, but
% we could also show LMS and/or light flux if we want to.

% Finally, the subject undergoes practice trials. These trials are
% identical in structure to the trials of the actual experiment. After each
% trial, this code will display the recorded data from each instrument, but
% this has not yet been implemented. Subjects can undego as many practice
% trials as desired. Each practice trial is currently configured to display
% a 100% contrast pulse of melanopsin-directed stimulation.

% INPUT:
%   - protocolParams: a structure describing the parameters of relevant
%   experiment. The specifics of the protocolParams will be applied to
%   create the practice trials (as well as to convey more general
%   information about the session, including date, observerID, session
%   number, which computer operates what, etc.)
%   - ol: object to control the OneLight


% This function is still a work in process. Specifically, it needs a way in
% which we can feed the ol object and protocolParams into the function from
% each computer, or at least that's the way HMM understands it as of 12/15



%% Prepare equipment and subject

% we're going to be running scratch trials where everything is simulated 
% except the piece of hardware in question. the idea is that we'll run the
% trial, make sure that the single hardware piece gave appropriate output,
% then move onto the next piece of hardware

% first make a copy of the protocolParams that we'll edit to run each
% scratch trial
scratchProtocolParams = protocolParams;
scratchProtocolParams.setup = true; % this option tells the results recorded as part of this setup to live in a different directory from the real data
scratchProtocolParams.simulate.oneLight = true;
scratchProtocolParams.simulate.microphone = true;
scratchProtocolParams.simulate.speaker = false;
scratchProtocolParams.simulate.emg = true;
scratchProtocolParams.simulate.pupil = true;
scratchProtocolParams.simulate.udp = true;
scratchProtocolParams.simulate.observer = false;
scratchProtocolParams.simulate.operator = false;


% have to specify where to save, here a special setup dir with the normal session dir, rather than the
% traditional session dir where the actual data will go. this information
% is ultimately necessary to clean up or display some of the data that
% comes out of this setup.
if any(cellfun(@(x) sum(strcmp(x,'base')),protocolParams.myRoles))
    savePath = fullfile(getpref(scratchProtocolParams.protocol, 'DataFilesBasePath'),scratchProtocolParams.observerID, scratchProtocolParams.todayDate, scratchProtocolParams.sessionName, 'setup');
end


% check IR camera setup first
% note that here we're just opening the camera and displaying the output,
% giving time for the user to adjust the setup so that the pupil is
% properly positioned. That is, unlike the rest of the checks, we're not
% actually running a scratch trial.
% only the pupil computer, monkfish/iMac do anything here
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

% microphone just relies on the base, so only the base needs to get
% involved
if any(cellfun(@(x) sum(strcmp(x,'base')),protocolParams.myRoles))
    % check IR camera status, and prompt the operator is ready
    commandwindow;
    fprintf('- Checking the microphone. Press <strong>Enter</strong> when ready.\n');
    input('');
    
    
    
    % make scratch trial short and sweet
    scratchProtocolParams.trialTypeOrder = [1];
    scratchProtocolParams.nTrials = length(scratchProtocolParams.trialTypeOrder);
    
    % make trial as short as possible because we just care if the audio
    % recording is working
    scratchProtocolParams.trialMinJitterTimeSec = 0;
    scratchProtocolParams.trialMaxJitterTimeSec = 0;
    scratchProtocolParams.trialBackgroundTimeSec = 0;
    scratchProtocolParams.trialISITimeSec = 0;
    
    % normal response window
    scratchProtocolParams.trialResponseWindowTimeSec = 4;
    
    % all other hardware will be simulated
    scratchProtocolParams.simulate.microphone = false; 
    
    % while loop to do multiple practice trials until the operator is happy
    % with the audio output
    toContinue = 'n';
    while toContinue ~= 'y'
        
        % get rid of previous scratch trial if we're doing more than one
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
            
            % prompt the user to ask if the audio looks god
            toContinue = GetWithDefault('Does the audio look OK? If yes, setup will continue', 'y');
            
            close(plotFig)
        end
    end
    
    % once we have a good audio practice trial, save it out with
    % _audioCheck appended
    movefile(fullfile(savePath, [scratchProtocolParams.sessionName '_' scratchProtocolParams.protocolOutputName sprintf('_acquisition%02d_base.mat',1)]), fullfile(savePath, [scratchProtocolParams.sessionName '_' scratchProtocolParams.protocolOutputName sprintf('_acquisition%02d_base_audioCheck.mat',1)]));
end
    
    % 
% now show subjects the range of contrasts to see if any of them make the
% subject uncomfortable
% we only need the base computer to drive the OneLight (and we'll be simulating everything else)    
if any(cellfun(@(x) sum(strcmp(x,'base')),protocolParams.myRoles))
    scratchProtocolParams.simulate.oneLight = true;
    scratchProtocolParams.simulate.microphone = true;
    scratchProtocolParams.simulate.speaker = false;
    scratchProtocolParams.simulate.emg = true;
    scratchProtocolParams.simulate.pupil = true;
    scratchProtocolParams.simulate.udp = true;
    scratchProtocolParams.simulate.observer = false;
    scratchProtocolParams.simulate.operator = false;
    scratchProtocolParams.trialResponseWindowTimeSec = 0; % don't need the subjects to respond to anything for this
    
    % range of contrasts we're going to show; this vector is only used to
    % tell the operator what the subject is about to see
    contrastValues = {100, 200, 400};
    % counter to indicate index of contrastValues
    loopIndex = 1;
    
    % loop over scratch trials, each trial at a different contrast level
    for contrastLevel = [3 2 1]
        
        % tell the operator what they're about to see
        fprintf('- Now showing %02d%% melanopsin contrast\n', contrastValues{loopIndex});
        
        % grab the relevant contrast level
        scratchProtocolParams.trialTypeOrder = [contrastLevel];
        
        % execute the acquisition (1 acquisition = 1 trial)
        ApproachEngine(ol,scratchProtocolParams,'acquisitionNumber', contrastLevel,'verbose',false);
        if any(cellfun(@(x) sum(strcmp(x,'base')),protocolParams.myRoles))
            % append label '_contrastCheck' to indicate what this data
            % output is -- note that we're probably not going to be doing
            % anything with this, so do we really ultimately want to save
            % it?
            movefile(fullfile(savePath, [scratchProtocolParams.sessionName '_' scratchProtocolParams.protocolOutputName sprintf('_acquisition%02d_base.mat',contrastLevel)]), fullfile(savePath, [scratchProtocolParams.sessionName '_' scratchProtocolParams.protocolOutputName sprintf('_acquisition%02d_base_contrastCheck.mat',contrastLevel)]));
        end
        % update counter
        loopIndex = loopIndex+1;
    end
end

% now the subject can practice the whole trial procedure

% this will all be done in a while loop so the subject can practice as many
% trails as desired
toContinue = 'y';
% grab a fresh copy of the protocolParams, because we want the details of
% the real experiment. we're also not simulating anything
scratchProtocolParams = protocolParams;

% we're just going to be practice trials of 100% mel contrast (1
% acquisition = 1 trial)
scratchProtocolParams.trialTypeOrder = [3];
scratchProtocolParams.nTrials = length(scratchProtocolParams.trialTypeOrder);
scratchProtocolParams.setup = true; % but still save in the setup directory

counter = 1;
while toContinue ~= 'n'
    
    % execute the practice acquisition (1 acquisition = 1 trial)
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