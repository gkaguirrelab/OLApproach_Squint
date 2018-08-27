function dictionary = OLDirectionParamsDictionary_Squint(varargin)
% Defines a dictionary with parameters for named nominal directions
%
% Syntax:
%   dictionary = OLDirectionParamsDictionary()
%
% Description:
%    Define a dictionary of named directions of modulation, with
%    corresponding nominal parameters. Types of directions, and their
%    corresponding fields, are defined in OLDirectionParamsDefaults,
%    and validated by OLDirectionParamsValidate.
%
% Inputs:
%    None.
%
% Outputs:
%    dictionary - dictionary with all parameters for all desired directions
%
% Optional key/value pairs:
%    'alternateDictionaryFunc' - String with name of alternate dictionary
%                          function to call. This must be a function on the
%                          path. Default of empty results in using this
%                          function.
%
% Notes:
%    None.
%
% See also: OLBackgroundParamsDictionary

% History:
%    06/22/17  npc  Wrote it. 06/28/18  dhb  backgroundType ->
%                   backgroundName. Use names of routine that creates
%                   backgrounds.
%              dhb  Add name field. 
%              dhb  Explicitly set contrasts in each case, rather than rely
%                   on defaults. 
%              dhb  Bring in params.photoreceptorClasses.  These go with
%                   directions/backgrounds. 
%              dhb  Bring in params.useAmbient. This goes with directions/
%                   backgrounds.
%    07/05/17  dhb  Bringing up to speed. :
%    07/19/17  npc  Added a type for each background. For now, there is 
%                   only one type: 'pulse'. Defaults and checking are done 
%                   according to type. params.photoreceptorClasses is now a
%                   cell array
%    07/22/17  dhb  No more modulationDirection field. 
%    07/23/17  dhb  Comment field meanings. 
%    07/27/17  dhb  Light flux entry 
%    01/24/18  dhb,jv  Finished adding support for modulations
%              jv   Renamed direction types: pulse is now unipolar,
%                   modulation is now bipolar
%	 01/25/18  jv	Extract defaults generation, validation of params.
%    02/15/18  jv   Parameters are now objects
%    03/31/18  dhb  Add alternateDictionaryFunc key/value pair.
%              dhb  Delete obsolete notes and see alsos.
%    04/09/18  dhb  Removing light flux parameters. Use a local dictionary!

% Parse input
p = inputParser;
p.KeepUnmatched = true;
p.addParameter('alternateDictionaryFunc','',@ischar);
p.parse(varargin{:});

% Check for alternate dictionary, call if so and then return.
% Otherwise this is the dictionary function and we execute it.
% The alternate function must be on the path.
if (~isempty(p.Results.alternateDictionaryFunc))
    dictionaryFunction = str2func(sprintf('@%s',p.Results.alternateDictionaryFunc));
    dictionary = dictionaryFunction();
    return;
end

%% Initialize dictionary
dictionary = containers.Map();




%% MaxMel_unipolar_275_60_667
% Direction for maximum unipolar contrast melanopsin step
%   Field size: 27.5 deg
%   Pupil diameter: 6 mm -- for use with 6 mm artificial pupil as part of
%   pupillometry
%   bipolar contrast: 66.7%
%
% Bipolar contrast is specified to generate, but the result is a 400% unipolar
% contrast step up relative to the background.
params = OLDirectionParams_Unipolar;
params.baseName = 'MaxMel';
params.primaryHeadRoom = 0.0;
params.baseModulationContrast = 2/3;
params.fieldSizeDegrees = 27.5;
params.pupilDiameterMm = 6.0;
params.photoreceptorClasses = {'LConeTabulatedAbsorbance','MConeTabulatedAbsorbance','SConeTabulatedAbsorbance','Melanopsin'};
params.modulationContrast = [params.baseModulationContrast];
params.whichReceptorsToIsolate = [4];
params.whichReceptorsToIgnore = [];
params.whichReceptorsToMinimize = [];
params.backgroundName = 'MelanopsinDirected_275_60_667';
params.name = OLDirectionNameFromParams(params);
if OLDirectionParamsValidate(params)
    % All validations OK. Add entry to the dictionary.
    dictionary(params.name) = params;
end




%% MaxLMS_unipolar_275_60_667
% Direction for maximum unipolar contrast LMS step
%   Field size: 27.5 deg
%   Pupil diameter: 6 mm -- for use with 6 mm artificial pupil with
%   pupillometry
%   bipolar contrast: 66.7%
%
% Bipolar contrast is specified to generate, but the result is a 400% unipolar
% contrast step up relative to the background.
params = OLDirectionParams_Unipolar;
params.baseName = 'MaxLMS';
params.primaryHeadRoom = 0.0;
params.baseModulationContrast = 2/3;
params.fieldSizeDegrees = 27.5;
params.pupilDiameterMm = 6.0;
params.photoreceptorClasses = {'LConeTabulatedAbsorbance','MConeTabulatedAbsorbance','SConeTabulatedAbsorbance','Melanopsin'};
params.modulationContrast = [params.baseModulationContrast params.baseModulationContrast params.baseModulationContrast];
params.whichReceptorsToIsolate = [1 2 3];
params.whichReceptorsToIgnore = [];
params.whichReceptorsToMinimize = [];
params.backgroundName = 'LMSDirected_275_60_667';
params.name = OLDirectionNameFromParams(params);
if OLDirectionParamsValidate(params)
    % All validations OK. Add entry to the dictionary.
    dictionary(params.name) = params;
end







%% LightFlux_UnipolarBase
%
% Base params for unipolar light flux directions
params = OLDirectionParams_LightFluxChrom;
params.baseName = 'LightFlux';
params.polarType = 'unipolar';
params.desiredxy = [0.60 0.38];
params.whichXYZ = 'xyzCIEPhys10';
params.desiredMaxContrast = 4;
params.desiredLum = 221.45;

% These are the options that go to OLPrimaryInvSolveChrom
params.search.primaryHeadroom = 0.000;
params.search.primaryTolerance = 1e-6;
params.search.checkPrimaryOutOfRange = true;
params.search.lambda = 0;
params.search.whichSpdToPrimaryMin = 'leastSquares';
params.search.spdToleranceFraction = 30e-5;
params.search.chromaticityTolerance = 0.02;
params.search.optimizationTarget = 'maxContrast';
params.search.primaryHeadroomForInitialMax = 0.000;
params.search.maxSearchIter = 3000;
params.search.verbose = false;

params.name = 'LightFlux_UnipolarBase';
if OLDirectionParamsValidate(params)
    % All validations OK. Add entry to the dictionary.
    dictionary(params.name) = params;
end

%% LightFlux_Unipolar_BoxA
%
% Base params for unipolar light flux directions
params = OLDirectionParams_LightFluxChrom;
params.baseName = 'LightFlux';
params.polarType = 'unipolar';
params.desiredxy = [0.51013 0.40142];
params.whichXYZ = 'xyzCIEPhys10';
params.desiredMaxContrast = 4;
params.desiredLum = 1114.4;

% These are the options that go to OLPrimaryInvSolveChrom
params.search.primaryHeadroom = 0.000;
params.search.primaryTolerance = 1e-6;
params.search.checkPrimaryOutOfRange = true;
params.search.lambda = 0;
params.search.whichSpdToPrimaryMin = 'leastSquares';
params.search.spdToleranceFraction = 1e-1;
params.search.chromaticityTolerance = 0.01;
params.search.optimizationTarget = 'maxContrast';
params.search.primaryHeadroomForInitialMax = 0.000;
params.search.maxSearchIter = 3000;
params.search.verbose = false;

params.name = 'LightFlux_Unipolar_BoxA';
if OLDirectionParamsValidate(params)
    % All validations OK. Add entry to the dictionary.
    dictionary(params.name) = params;
end

%% MaxLMS_chrom_unipolar_275_60_400
% Direction for maximum unipolar contrast LMS step
%   Field size: 27.5 deg
%   Pupil diameter: 6 mm
%   Unipolar contrast: 400%

params = OLDirectionParams_Unipolar;
params.baseName = 'MaxLMS_chrom';
params.baseModulationContrast = 4;
params.fieldSizeDegrees = 27.5;
params.pupilDiameterMm = 6.0;
params.photoreceptorClasses = {'LConeTabulatedAbsorbance','MConeTabulatedAbsorbance','SConeTabulatedAbsorbance','Melanopsin'};
params.backgroundName = 'LMSDirected_chrom_275_60_4000';

% These are the options that go to OLPrimaryInvSolveChrom
params.targetContrast = [params.baseModulationContrast params.baseModulationContrast params.baseModulationContrast 0];
params.search.primaryHeadroom = 0.005;
params.search.primaryTolerance = 1e-6;
params.search.checkPrimaryOutOfRange = true;
params.search.lambda = 0;
params.search.whichSpdToPrimaryMin = 'leastSquares';
params.search.chromaticityTolerance = 0.03;
params.search.lumToleranceFraction = 0.2;
params.search.optimizationTarget = 'receptorContrast';
params.search.primaryHeadroomForInitialMax = 0.005;
params.search.maxSearchIter = 3000;
params.search.verbose = false;

params.name = OLDirectionNameFromParams(params);
if OLDirectionParamsValidate(params)
    dictionary(params.name) = params;
end

%% MaxMel_chrom_unipolar_275_60_400
% Direction for maximum unipolar contrast Mel step
%   Field size: 27.5 deg
%   Pupil diameter: 6 mm
%   Unipolar contrast: 400%

params = OLDirectionParams_Unipolar;
params.baseName = 'MaxMel_chrom';
params.baseModulationContrast = 4;
params.fieldSizeDegrees = 27.5;
params.pupilDiameterMm = 6.0;
params.photoreceptorClasses = {'LConeTabulatedAbsorbance','MConeTabulatedAbsorbance','SConeTabulatedAbsorbance','Melanopsin'};
params.backgroundName = 'MelDirected_chrom_275_60_4000';

% These are the options that go to OLPrimaryInvSolveChrom
params.targetContrast = [0 0 0 params.baseModulationContrast];
params.search.primaryHeadroom = 0.005;
params.search.primaryTolerance = 1e-6;
params.search.checkPrimaryOutOfRange = true;
params.search.lambda = 0;
params.search.whichSpdToPrimaryMin = 'leastSquares';
params.search.chromaticityTolerance = 0.03;
params.search.lumToleranceFraction = 0.2;
params.search.optimizationTarget = 'receptorContrast';
params.search.primaryHeadroomForInitialMax = 0.005;
params.search.maxSearchIter = 3000;
params.search.verbose = false;

params.name = OLDirectionNameFromParams(params);
if OLDirectionParamsValidate(params)
    dictionary(params.name) = params;
end

%% LightFlux_chrom_unipolar_275_60_4000
% Direction for maximum unipolar contrast "LightFlux" step
%   Field size: 27.5 deg
%   Pupil diameter: 6 mm
%   Unipolar contrast: 400%

params = OLDirectionParams_Unipolar;
params.baseName = 'LightFlux_chrom';
params.baseModulationContrast = 4;
params.fieldSizeDegrees = 27.5;
params.pupilDiameterMm = 6.0;
params.photoreceptorClasses = {'LConeTabulatedAbsorbance','MConeTabulatedAbsorbance','SConeTabulatedAbsorbance','Melanopsin'};
params.backgroundName = 'LightFlux_chrom_275_60_4000';

% These are the options that go to OLPrimaryInvSolveChrom
params.targetContrast = [params.baseModulationContrast params.baseModulationContrast params.baseModulationContrast params.baseModulationContrast];
params.search.primaryHeadroom = 0.005;
params.search.primaryTolerance = 1e-6;
params.search.checkPrimaryOutOfRange = true;
params.search.lambda = 0;
params.search.whichSpdToPrimaryMin = 'leastSquares';
params.search.chromaticityTolerance = 0.03;
params.search.lumToleranceFraction = 0.6;
params.search.optimizationTarget = 'receptorContrast';
params.search.primaryHeadroomForInitialMax = 0.005;
params.search.maxSearchIter = 3000;
params.search.verbose = false;

params.name = OLDirectionNameFromParams(params);
if OLDirectionParamsValidate(params)
    dictionary(params.name) = params;
end

end