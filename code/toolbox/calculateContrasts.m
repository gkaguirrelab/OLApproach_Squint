function [ contrasts, contrastStrings ] = calculateContrasts(backgroundSpd, modulationSpd, T_receptors, photoreceptorClasses)

backgroundReceptors = T_receptors*backgroundSpd;
receptors = T_receptors * modulationSpd;
LMScontrasts = (receptors - backgroundReceptors) ./ backgroundReceptors;

contrasts = LMScontrasts;
contrastStrings = photoreceptorClasses;

[postreceptoralContrasts, postreceptoralStrings] = ComputePostreceptoralContrastsFromLMSContrasts(contrasts(1:3));

contrasts = [contrasts; postreceptoralContrasts];
contrastStrings = [contrastStrings, postreceptoralStrings];

end
