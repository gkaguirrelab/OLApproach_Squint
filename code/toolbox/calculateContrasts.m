function [ contrasts, contrastStrings ] = calculateContrasts(backgroundSpd, modulationSpd, T_receptors, photoreceptorClasses)
% Quick way to determine the contrast for a specific unipolar modulation.
%
% Syntax:
%  [ contrasts, contrastStrings ] = calculateContrasts(backgroundSpd, modulationSpd, T_receptors, photoreceptorClasses)

% Description:
%   This function calculates the unipolar contrast on the (L, M, and S) cones,
%   melanopsin, as well the postreceptoral channels (L-M, S-(L+M), and
%   LMS). The guts of this function were ripped from the OneLightToolbox.
%   For now, the routine expects T_receptors and photoreceptor classes to
%   have this implied structure: L cones -> M cones -> S cones -> Melanopsin.

% Inputs:
%   backgroundSpd         - A vector summarizing the background spectrum,
%                           where each value is a power in some wavelength
%                           band.
%   modulationSpd         - A vector summarizing the modulation or
%                           stimulating spectrum, where each value is a
%                           power in some wavelength band.
%   T_receptors           - A 4xN matrix, where each row represents the
%                           spectral sensitivity functions of the L, M, and
%                           S cones as well as melanopsin. The intended
%                           order: L cones -> M cones -> S cones ->
%                           Melanopsin.
%   photoreceptorClasses  - A 1x4 cell array, where each item in the cell
%                           array defines the identify of the corresponding
%                           row of the T_receptors matrix.
%
% Note: backgroundSpd, modulationSpd, and T_receptors are expected to have
% the same sampling (i.e same wavelength bins).
%
% Outputs:
%   contrasts               - A 7x1 element vector where each element 
%                             refers to the contrast on a given mechanism.
%   contrastStrings         - A 7x1 cell array, which defines the contrast
%                             mechanism of the relevant element in the
%                             contrasts vector



backgroundReceptors = T_receptors*backgroundSpd;
receptors = T_receptors * modulationSpd;
LMScontrasts = (receptors - backgroundReceptors) ./ backgroundReceptors;

contrasts = LMScontrasts;
contrastStrings = photoreceptorClasses;

[postreceptoralContrasts, postreceptoralStrings] = ComputePostreceptoralContrastsFromLMSContrasts(contrasts(1:3));

contrasts = [contrasts; postreceptoralContrasts];
contrastStrings = [contrastStrings, postreceptoralStrings];

end
