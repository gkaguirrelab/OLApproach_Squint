function [ XYChromaticity, chromaticityAccumulator ] = calculateChromaticity( DirectionObject, varargin)
% Calculates the chromaticity of the background spectrum associated with the DirectionObject.
%
% Syntax:
%  [ XYChromaticity, chromaticityAccumulator ] = calculateChromaticity( DirectionObject)

% Description:
%   This function uses the validation measurements contained within a
%   DirectionObject to determine the chromaticity (in X,Y coordinates) of
%   the background spectrum associated with the DirectionObject.

% Inputs:
%   DirectionObject       - The direction object for the relevant stimulus
%                           class. Validation measurements stored within
%                           this direction object are used for calculating
%                           the chromaticity.
% Optional Key-Value Pairs:
%   whichValidation       - A string or cell array of strings that describe
%                           which validation measurments we care about for
%                           this computation of chromaticity. Within the
%                           DirectionObject, each validation measurement
%                           can be associated with a label. If we only want
%                           validations with a corresponding label to be
%                           included, we'd specify the appropriate label or
%                           labels with this key-value pair. default), or
%                           'on.' If set to 'on,' then the routine will
%                           print to the console which validation measures,
%                           if any, do not pass our exclusion criteria.
% Outputs:
%   XYChromaticity        - A 2x1 vector where the first element is the X
%                           coordinate and the second element is the Y
%                           coordinate of the calculated chromaticity of
%                           the background spectrum. These values are the
%                           median values across all relevant validation
%                           measurements.
%   chromaticityAccumulator - An Nx2 matrix, where N corresponds to the
%                           number of relevant validation measurements. The
%                           first row contains the X coordinates of the
%                           chromaticity calulation for each validation
%                           measurement. The second row contains the Y
%                           coordinates of the chromaticity calculation for
%                           each validation measurment.



%% Parse input
p = inputParser; p.KeepUnmatched = true;
p.addParameter('whichValidation', 'combined')


p.parse(varargin{:});

%% determine which validation measurements we care about, on the basis of the 'whichValidations' key-value pair
if strcmp(p.Results.whichValidation, 'combined')
    firstIndex = 1;
    lastIndex = length(DirectionObject.describe.validation);
    validationIndices = firstIndex:lastIndex;
else
    validationIndices = [];
    for ii = 1:length(DirectionObject.describe.validation)
        if any(strcmp(DirectionObject.describe.validation(ii).label, p.Results.whichValidation))
            validationIndices = [validationIndices, ii];
        end
    end
end
            


% set up some basic variables
load T_xyzCIEPhys10
S = [380 2 201];
T_xyz = SplineCmf(S_xyzCIEPhys10,683*T_xyzCIEPhys10,S);

nValidations = length(DirectionObject.describe.validation);

chromaticityAccumulator = [];
counter = 1;
for vv = validationIndices
    backgroundSpd = DirectionObject.describe.validation(vv).SPDbackground.measuredSPD;
    chromaticity = T_xyz(1:2,:)*backgroundSpd/sum(T_xyz*backgroundSpd);
    chromaticityAccumulator(counter,1) = chromaticity(1);
    chromaticityAccumulator(counter,2) = chromaticity(2);
    counter = counter + 1;
end

XYChromaticity(1) = median(chromaticityAccumulator(:,1));
XYChromaticity(2) = median(chromaticityAccumulator(:,2));

end

