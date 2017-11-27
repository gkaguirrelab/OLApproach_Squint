function [emgDataStruct] = SquintRecordEMG(varargin)
% function [emgDataStruct] = SquintRecordEMG(varargin)
%
% Utility routine to openn communication with a LabJack device, and then
% record data for a specified number of seconds. 
%
% OUTPUT:
%    emgDataStruct - A structure with the fields timebase and response.
%    timebase is in units of msecs. Response is the voltage measured from
%    the EMG device during the recording period.
%
%  'channelIDs' - list of  channels to aquire from (AIN1 = 1, AIN2 = 2, AIN3 = 3)


%% Parse input
p = inputParser;
p.addParameter('recordingDurationSecs',20,@isnumeric);
p.addParameter('channelIDs',[1 3],@isnumeric);
p.addParameter('frequencyInHz',5000,@isnumeric);
p.addParameter('simulate',false,@islogical);
p.addParameter('verbose',false,@islogical);

p.parse(varargin{:});

if p.Results.simulate
    emgDataStruct.timebase = 0:1/p.Results.frequencyInHz*1000:(p.Results.recordingDurationSecs*1000)-(1/p.Results.frequencyInHz*1000);
    % Simulate a 1 Hz sinusoid with some noise
    emgDataStruct.response = sin(emgDataStruct.timebase/1000*2*pi);
    emgDataStruct.response = emgDataStruct.response + ...
        normrnd(0,1,size(emgDataStruct.timebase,1),size(emgDataStruct.timebase,2));
else
    
    % Instantiate a LabJack object to handle communication with the device
    labjackOBJ = LabJackU6('verbosity', double(p.Results.verbose));
    
    try
        % Configure analog input sampling
        labjackOBJ.configureAnalogDataStream(p.Results.channelIDs, p.Results.frequencyInHz);
        
        % Aquire the data
        labjackOBJ.startDataStreamingForSpecifiedDuration(p.Results.recordingDurationSecs);
        
        % Place the data in a response structure
        %% NEED TO DO SOME WORK HERE TO LINK THE UNITS OF TIME TO THE STANDARD MSECS OF OUR PACKETS
        emgDataStruct.timebase = labjackOBJ.timeAxis;
        emgDataStruct.response = labjackOBJ.data(:,1);
        emgDataStruct.params = p.Results;
        
        % Close-up shop
        labjackOBJ.shutdown();
        
    catch err
        % Close up shop
        labjackOBJ.shutdown();
        rethrow(err)
    end % try-catch
end % is this real life or a simulation?

end % function
