function [ XYChromaticity, chromaticityAccumulator ] = calculateChromaticity( DirectionObject)

% set up some basic variables
load T_xyz1931
S = [380 2 201];
T_xyz = SplineCmf(S_xyz1931,683*T_xyz1931,S);

nValidations = length(DirectionObject.describe.validation);

chromaticityAccumulator = [];
for vv = 1:nValidations
    backgroundSpd = DirectionObject.describe.validation(vv).SPDbackground.measuredSPD;
    chromaticity = T_xyz(1:2,:)*backgroundSpd/sum(T_xyz*backgroundSpd);
    chromaticityAccumulator(vv,1) = chromaticity(1);
    chromaticityAccumulator(vv,2) = chromaticity(2);
end

XYChromaticity(1) = median(chromaticityAccumulator(:,1));
XYChromaticity(2) = median(chromaticityAccumulator(:,2));

end

