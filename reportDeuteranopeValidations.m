fprintf('\n<strong>***Pre-Experiment***</strong>\n');
fprintf('\n<strong>For melanopsin stimuli:</strong>\n');
MelValidation = summarizeValidation(MaxMelDirection, 'plot', 'off');
fprintf('\tL Cone Contrast: %4.2f %%\n', median(MelValidation.LConeContrast(6:10))*100);
fprintf('\tS Cone Contrast: %4.2f %%\n',  median(MelValidation.SConeContrast(6:10))*100);
fprintf('\tMelanopsin Contrast: %4.2f %%\n',  median(MelValidation.MelanopsinContrast(6:10))*100);


fprintf('\n<strong>For L+S stimuli:</strong>\n');
LMSValidation = summarizeValidation(MaxLMSDirection, 'plot', 'off');
fprintf('\tL Cone Contrast: %4.2f %%\n', median(LMSValidation.LConeContrast(6:10))*100);
fprintf('\tS Cone Contrast: %4.2f %%\n',  median(LMSValidation.SConeContrast(6:10))*100);
fprintf('\tMelanopsin Contrast: %4.2f %%\n',  median(LMSValidation.MelanopsinContrast(6:10))*100);



fprintf('\n<strong>For lightFlux stimuli:</strong>\n');
LightFluxValidation = summarizeValidation(LightFluxDirection, 'plot', 'off');
fprintf('\tL Cone Contrast: %4.2f %%\n', median(LightFluxValidation.LConeContrast(6:10))*100);
fprintf('\tS Cone Contrast: %4.2f %%\n',  median(LightFluxValidation.SConeContrast(6:10))*100);
fprintf('\tMelanopsin Contrast: %4.2f %%\n',  median(LightFluxValidation.MelanopsinContrast(6:10))*100);

fprintf('\n<strong>***Post-Experiment***</strong>\n');
fprintf('\n<strong>For melanopsin stimuli:</strong>\n');
MelValidation = summarizeValidation(MaxMelDirection, 'plot', 'off');
fprintf('\tL Cone Contrast: %4.2f %%\n', median(MelValidation.LConeContrast(11:15))*100);
fprintf('\tS Cone Contrast: %4.2f %%\n',  median(MelValidation.SConeContrast(11:15))*100);
fprintf('\tMelanopsin Contrast: %4.2f %%\n',  median(MelValidation.MelanopsinContrast(11:15))*100);


fprintf('\n<strong>For L+S stimuli:</strong>\n');
LMSValidation = summarizeValidation(MaxLMSDirection, 'plot', 'off');
fprintf('\tL Cone Contrast: %4.2f %%\n', median(LMSValidation.LConeContrast(11:15))*100);
fprintf('\tS Cone Contrast: %4.2f %%\n',  median(LMSValidation.SConeContrast(11:15))*100);
fprintf('\tMelanopsin Contrast: %4.2f %%\n',  median(LMSValidation.MelanopsinContrast(11:15))*100);



fprintf('\n<strong>For lightFlux stimuli:</strong>\n');
LightFluxValidation = summarizeValidation(LightFluxDirection, 'plot', 'off');
fprintf('\tL Cone Contrast: %4.2f %%\n', median(LightFluxValidation.LConeContrast(11:15))*100);
fprintf('\tS Cone Contrast: %4.2f %%\n',  median(LightFluxValidation.SConeContrast(11:15))*100);
fprintf('\tMelanopsin Contrast: %4.2f %%\n',  median(LightFluxValidation.MelanopsinContrast(11:15))*100);