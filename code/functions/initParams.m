function params = initParams(exp)
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