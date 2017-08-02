function params = initParams(exp)
% initParams - Loads config file to get the params struct.
%
% Usage:
%     params = initParams(exp)
%
% Description:
%     Loads a config file which contains information about the experimental
%     paradigm. I DONT THINK WE NEED THIS. THIS SHOULD BE CHANGED TO A
%     DICTIONARY CALL
%     
% Input:
%     exp - Know where the config file lives. 

% Output:
%     params - Stuct containing starts/stops and other information about experiment. 
%
% Optional key/value pairs.
%    None.
%
% See also:

% 8/2/17  mab  Split from experiment and tried to add comments.

% params = initParams(exp)
% Initialize the parameters

% Much with the paths a little bit.
[~, tmp, suff] = fileparts(exp.configFileName);
exp.configFileName = fullfile(exp.configFileDir, [tmp, suff]);

% Load the config file for this condition.
cfgFile = ConfigFile(exp.configFileName);

% Convert all the ConfigFile parameters into simple struct values.
params = convertToStruct(cfgFile);
params.cacheDir = fullfile(exp.baseDir, 'cache');

% Load the calibration file.
cType = OLCalibrationTypes.(params.calibrationType);
params.oneLightCal = LoadCalFile(cType.CalFileName);

% Setup the cache.
params.obsID = exp.subject;
file_names = allwords(params.modulationFiles,',');
for i = 1:length(file_names)
    % Create the cache file name.
    params.cacheFileName{i} = file_names{i};
end

end