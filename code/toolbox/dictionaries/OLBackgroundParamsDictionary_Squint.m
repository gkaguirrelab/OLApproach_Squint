function dictionary = OLBackgroundParamsDictionary(varargin)
% Defines a dictionary with parameters for named nominal backgrounds
%
% Syntax:
%   dictionary = OLBackgroundParamsDictionary()
%
% Description:
%    Define a dictionary of named backgrounds of modulation, with
%    corresponding nominal parameters.
%
% Inputs:
%    None.
%
% Outputs:
%    dictionary         -  Dictionary with all parameters for all desired
%                          backgrounds
%
% Optional key/value pairs:
%    'alternateDictionaryFunc' - String with name of alternate dictionary
%                          function to call. This must be a function on the
%                          path. Default of empty results in using this
%                          function.
%
% Notes:
%    * TODO:
%          i) add type 'BackgroundHalfOn' - Primaries set to 0.5;
%          ii) add type 'BackgroundEES' - Background metameric to an equal 
%              energy spectrum, scaled in middle of gamut.
%
% See also: 
%    OLBackgroundParams, OLDirectionParamsDictionary.

% History:
%    06/28/17  dhb  Created from direction version.
%    06/28/18  dhb  backgroundType -> backgroundName. Use names of routine 
%                   that creates backgrounds.
%              dhb  Add name field.
%              dhb  Bring in params.photoreceptorClasses.  These go with 
%                   directions/backgrounds.
%              dhb  Bring in params.useAmbient.  This goes with directions/
%                   backgrounds.
%    06/29/18  dhb  More extended names to reflect key parameters, so that 
%                   protocols can check
%    07/19/17  npc  Added a type for each background. For now, there is 
%                   only one type: 'basic'. 
%                   Defaults and checking are done according to type. 
%                   params.photoreceptorClasses is now a cell array.
%    07/22/17  dhb  No more modulationDirection field.
%    01/25/18  jv   Extract default params generation, validation.
%    02/07/18  jv   Updated to use OLBackgroundParams objects
%    03/26/18  jv, dhb Fix type in modulationContrast field of
%                   LMSDirected_LMS_275_60_667.
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

% Initialize dictionary
dictionary = containers.Map();


%% MelanopsinDirected_275_60_667
% Background to allow maximum unipolar contrast melanopsin modulations
%   Field size: 27.5 deg
%   Pupil diameter: 6 mm
%   bipolar contrast: 66.7%
%
% Bipolar contrast is specified to generate, this background is also used
% for a 400% unipolar pulse
params = OLBackgroundParams_Optimized;
params.baseName = 'MelanopsinDirected';
params.baseModulationContrast = 4/6;
params.primaryHeadRoom = 0.00;
params.pupilDiameterMm = 6;
params.photoreceptorClasses = {'LConeTabulatedAbsorbance','MConeTabulatedAbsorbance','SConeTabulatedAbsorbance','Melanopsin'};
params.modulationContrast = [4/6];
params.whichReceptorsToIsolate = {[4]};
params.whichReceptorsToIgnore = {[]};
params.whichReceptorsToMinimize = {[]};
params.directionsYoked = [0];
params.directionsYokedAbs = [0];
params.name = OLBackgroundNameFromParams(params);
if OLBackgroundParamsValidate(params)
    % All validations OK. Add entry to the dictionary.
    dictionary(params.name) = params;
end

%% LMSDirected_LMS_275_60_667
% Background to allow maximum unipolar contrast LMS modulations
%   Field size: 27.5 deg
%   Pupil diameter: 6 mm
%   bipolar contrast: 66.7%
%
% Bipolar contrast is specified to generate, this background is also used
% for a 400% unipolar pulse
params = OLBackgroundParams_Optimized;
params.baseName = 'LMSDirected';
params.baseModulationContrast = 4/6;
params.primaryHeadRoom = 0.00;
params.pupilDiameterMm = 6;
params.photoreceptorClasses = {'LConeTabulatedAbsorbance','MConeTabulatedAbsorbance','SConeTabulatedAbsorbance','Melanopsin'};
params.modulationContrast = {[4/6 4/6 4/6]};
params.whichReceptorsToIsolate = {[1 2 3]};
params.whichReceptorsToIgnore = {[]};
params.whichReceptorsToMinimize = {[]};
params.directionsYoked = [1];
params.directionsYokedAbs = [0];
params.name = OLBackgroundNameFromParams(params);
if OLBackgroundParamsValidate(params)
    % All validations OK. Add entry to the dictionary.
    dictionary(params.name) = params;
end

%% LightFlux_UnipolarBase
%
% % Base params for unipolar light flux modulation backgrounds
% %params = OLBackgroundParams_LightFluxChrom;
% params.baseName = 'LightFlux';
% params.polarType = 'unipolar';
% params.desiredxy = [0.45,0.45];
% params.whichXYZ = 'xyzCIEPhys10';
% params.desiredMaxContrast = 4;
% 
% % These are the options that go to OLPrimaryInvSolveChrom
% params.search.primaryHeadRoom = 0.005;
% params.search.primaryTolerance = 1e-6;
% params.search.checkPrimaryOutOfRange = true;
% params.search.initialLuminanceFactor = 0.2;
% params.search.lambda = 0;
% params.search.spdToleranceFraction = 0.005;
% params.search.chromaticityTolerance = 0.0001;
% params.search.optimizationTarget = 'maxLum';
% params.search.primaryHeadroomForInitialMax = 0.005;
% params.search.maxScaleDownForStart = 2;
% params.search.maxSearchIter = 300;
% params.search.verbose = false;
% 
% params.name = 'LightFlux_UnipolarBase';
% if OLBackgroundParamsValidate(params)
%     % All validations OK. Add entry to the dictionary.
%     dictionary(params.name) = params;
% end


%% LMSDirected_chrom_275_60_400
% Background to allow maximum unipolar contrast LMS modulations
%   Field size: 27.5 deg
%   Pupil diameter: 6 mm
%   Unipolar contrast: 400%
params = OLBackgroundParams_Optimized;
params.baseName = 'LMSDirected_chrom';
params.baseModulationContrast = 4;
params.fieldSizeDegrees = 27.5;
params.pupilDiameterMm = 6;
params.photoreceptorClasses = {'LConeTabulatedAbsorbance','MConeTabulatedAbsorbance','SConeTabulatedAbsorbance','Melanopsin'};

% These are the options that go to OLPrimaryInvSolveChrom
params.desiredxy = [0.5964,0.3813];
params.desiredxy = [0.58,0.365];

params.desiredLum = 150;
params.whichXYZ = 'xyzCIEPhys10';
params.targetContrast = [params.baseModulationContrast params.baseModulationContrast params.baseModulationContrast 0];
params.search.primaryHeadroom = 0.000;
params.search.primaryTolerance = 1e-6;
params.search.checkPrimaryOutOfRange = true;
params.search.lambda = 0;
params.search.whichSpdToPrimaryMin = 'leastSquares';
params.search.chromaticityTolerance = 0.03;
params.search.lumToleranceFraction = 0.1;
params.search.optimizationTarget = 'receptorContrast';
params.search.primaryHeadroomForInitialMax = 0.000;
params.search.maxSearchIter = 3000;
params.search.verbose = false;

params.name = OLBackgroundNameFromParams(params);
if OLBackgroundParamsValidate(params)
    dictionary(params.name) = params;
end

%% MelDirected_chrom_275_60_400
% Background to allow maximum unipolar contrast Mel modulations
%   Field size: 27.5 deg
%   Pupil diameter: 6 mm
%   Unipolar contrast: 400%
params = OLBackgroundParams_Optimized;
params.baseName = 'MelDirected_chrom';
params.baseModulationContrast = 4;
params.fieldSizeDegrees = 27.5;
params.pupilDiameterMm = 6;
params.photoreceptorClasses = {'LConeTabulatedAbsorbance','MConeTabulatedAbsorbance','SConeTabulatedAbsorbance','Melanopsin'};

% These are the options that go to OLPrimaryInvSolveChrom
params.desiredxy = [0.5964,0.3813];
params.desiredLum = 315;
params.whichXYZ = 'xyzCIEPhys10';
params.targetContrast = [0 0 0 params.baseModulationContrast];
params.search.primaryHeadroom = 0.000;
params.search.primaryTolerance = 1e-6;
params.search.checkPrimaryOutOfRange = true;
params.search.lambda = 0;
params.search.whichSpdToPrimaryMin = 'leastSquares';
params.search.chromaticityTolerance = 0.03;
params.search.lumToleranceFraction = 0.1;
params.search.optimizationTarget = 'receptorContrast';
params.search.primaryHeadroomForInitialMax = 0.000;
params.search.maxSearchIter = 3000;
params.search.verbose = false;

params.name = OLBackgroundNameFromParams(params);
if OLBackgroundParamsValidate(params)
    dictionary(params.name) = params;
end


%% LightFluxDirected_chrom_275_60_4000
% Background to allow maximum unipolar contrast LightFlux modulations
%   Field size: 27.5 deg
%   Pupil diameter: 6 mm
%   Unipolar contrast: 400%
params = OLBackgroundParams_Optimized;
params.baseName = 'LightFlux_chrom';
params.baseModulationContrast = 4;
params.fieldSizeDegrees = 27.5;
params.pupilDiameterMm = 6;
params.photoreceptorClasses = {'LConeTabulatedAbsorbance','MConeTabulatedAbsorbance','SConeTabulatedAbsorbance','Melanopsin'};

% These are the options that go to OLPrimaryInvSolveChrom
params.desiredxy = [0.5964,0.3813];
params.desiredLum = 210;
params.whichXYZ = 'xyzCIEPhys10';
params.targetContrast = [params.baseModulationContrast params.baseModulationContrast params.baseModulationContrast params.baseModulationContrast];
params.search.primaryHeadroom = 0.000;
params.search.primaryTolerance = 1e-6;
params.search.checkPrimaryOutOfRange = true;
params.search.lambda = 0;
params.search.whichSpdToPrimaryMin = 'leastSquares';
params.search.chromaticityTolerance = 0.03;
params.search.lumToleranceFraction = 0.3;
params.search.optimizationTarget = 'receptorContrast';
params.search.primaryHeadroomForInitialMax = 0.000;
params.search.maxSearchIter = 3000;
params.search.verbose = false;

params.name = OLBackgroundNameFromParams(params);
if OLBackgroundParamsValidate(params)
    dictionary(params.name) = params;
end

end