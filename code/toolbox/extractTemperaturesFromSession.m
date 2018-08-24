function temperatures = extractTemperaturesFromSession(participant,session)
    directory = fullfile(participant,session);
    directory = fullfile(getpref('OLApproach_Squint','DataPath'),'Experiments','OLApproach_Squint','SquintToPulse','DirectionObjects',directory);

    %% direction names    
    filenames = dir(fullfile(directory,'*Direction.mat')); % get all '...Direction.mat' files in directory
    filenames = string({filenames.name}); % convert to string array of filenames
    directionNames = erase(filenames,'.mat'); % convert to direction names, by remove '.mat' extension

    %% Load directions
    for f = filenames
        load(fullfile(directory,f));
    end

    %% Extract temperatures
    temperatures = table(); % pre-alloc table
    for d = directionNames % loop over directions
        tempTable = extractTemperaturesFromDirection(eval(d)); % get temperatures in table, from OLDirection object
        tempTable.direction = repmat(d,[height(tempTable) 1]); % add direction name to table
        temperatures = [temperatures; tempTable];              % add to previously extracted temperatures (from other objects)
    end
end

function temperatures = extractTemperaturesFromDirection(direction)
    tempers = []; % pre-alloc
    times = [];
    labels = {};  % pre-alloc
    validations = direction.describe.validation; % extract validations from OLDirection object
    for i = 1:numel(validations) % loop over validations
        if ~isempty(validations(i).temperatures) % check if temperature was recorded
            tempers = [tempers; validations(i).temperatures{1}.value; validations(i).temperatures{2}.value]; % extract pre- and post-spectral measurement temperature
            times = [times; validations(i).temperatures{1}.time; validations(i).temperatures{2}.time];
            labels = [labels; validations(i).label; validations(i).label]; % extract label (twice, once for pre- and once for post-spectral measurement temperature)
        end
    end
    
    % convert to Table()
    temperatures = table(); 
    temperatures.label = labels;
    temperatures.times = times;
    temperatures.temperature = tempers;
end