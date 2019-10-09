%% testNominalStimuli

wavelengths = 380:2:380+201*2 - 2;
gap = 0.3;
fontSize = 15;
%% Melanopsin
close all
combinedSPD = MaxMelDirection.ToPredictedSPD + MaxMelBackground.ToPredictedSPD + MaxMelBackground.calibration.computed.pr650MeanDark;
backgroundSPD =  MaxMelBackground.ToPredictedSPD + MaxMelBackground.calibration.computed.pr650MeanDark;
% just the background
plotFig = figure; hold on;
[ha, pos] = tight_subplot(1,2, gap);

axes(ha(1)); hold on;
plot(wavelengths, backgroundSPD, 'Color', 'k');
xlabel('Wavelength (nm)');
ylabel('Radiance')
yticks([]);
pbaspect([1 1 1])
set(gca, 'FontSize', fontSize);
set(gca, 'FontName', 'Helvetica Neue');

axes(ha(2)); hold on;
[contrasts, excitations] = ToDesiredReceptorContrast(MaxMelDirection, MaxMelBackground, T_receptors);
a = bar([excitations(3,1), excitations(4,1), excitations(2,1), excitations(1,1)], 'FaceColor', 'k');
a.BarWidth = 0.4;
xticks(1:4);
xticklabels({'S Cone', 'Melanopsin', 'M Cone', 'L Cone'})
xlim([0 5]);
xtickangle(30)
ylabel('Receptor Excitations')
yticks([]);
pbaspect([1 1 1])
set(gca, 'FontSize', fontSize);
set(gca, 'FontName', 'Helvetica Neue');
export_fig(plotFig, fullfile(getpref('melSquintAnalysis', 'melaAnalysisPath'), 'melSquintAnalysis', 'OSAFigures', 'MelBackground.pdf'), '-painters');


plotFig = figure; hold on;
[ha, pos] = tight_subplot(1,2, gap);

axes(ha(1)); hold on;
plot(wavelengths, backgroundSPD, 'Color', 'k');
plot(wavelengths, combinedSPD, 'Color', 'r');
xlabel('Wavelength (nm)');
ylabel('Radiance')
yticks([]);
pbaspect([1 1 1])
set(gca, 'FontSize', fontSize);
set(gca, 'FontName', 'Helvetica Neue');

axes(ha(2)); hold on;
[contrasts, excitations] = ToDesiredReceptorContrast(MaxMelDirection, MaxMelBackground, T_receptors);
b = bar([excitations(3,1) excitations(3,2); excitations(4,1) excitations(4,2); excitations(2,1), excitations(2,2); excitations(1,1), excitations(1,2)]);
b(1).FaceColor = 'k';
b(2).FaceColor = 'r';
xticklabels({'S Cone', 'Melanopsin', 'M Cone', 'L Cone'})
xlim([0 5]);
xtickangle(30)
ylabel('Receptor Excitations')
yticks([]);
pbaspect([1 1 1])
set(gca, 'FontSize', fontSize);
set(gca, 'FontName', 'Helvetica Neue');

export_fig(plotFig, fullfile(getpref('melSquintAnalysis', 'melaAnalysisPath'), 'melSquintAnalysis', 'OSAFigures', 'MelFull.pdf'), '-painters');

%% LMS

combinedSPD = MaxLMSDirection.ToPredictedSPD + MaxLMSBackground.ToPredictedSPD + MaxLMSBackground.calibration.computed.pr650MeanDark;
backgroundSPD =  MaxLMSBackground.ToPredictedSPD + MaxLMSBackground.calibration.computed.pr650MeanDark;
% just the background
plotFig = figure; hold on;
[ha, pos] = tight_subplot(1,2, gap);

axes(ha(1)); hold on;
plot(wavelengths, backgroundSPD, 'Color', 'k');
xlabel('Wavelength (nm)');
ylabel('Radiance')
yticks([]);
pbaspect([1 1 1])
set(gca, 'FontSize', fontSize);
set(gca, 'FontName', 'Helvetica Neue');

axes(ha(2)); hold on;
[contrasts, excitations] = ToDesiredReceptorContrast(MaxLMSDirection, MaxLMSBackground, T_receptors);
a = bar([excitations(3,1), excitations(4,1), excitations(2,1), excitations(1,1)], 'FaceColor', 'k');
a.BarWidth = 0.4;
xticklabels({'S Cone', 'Melanopsin', 'M Cone', 'L Cone'})
xlim([0 5]);
xtickangle(30)
pbaspect([1 1 1])
ylabel('Receptor Excitations')
yticks([]);
set(gca, 'FontSize', fontSize);
set(gca, 'FontName', 'Helvetica Neue');
export_fig(plotFig, fullfile(getpref('melSquintAnalysis', 'melaAnalysisPath'), 'melSquintAnalysis', 'OSAFigures', 'LMSBackground.pdf'), '-painters');


plotFig = figure; hold on;
[ha, pos] = tight_subplot(1,2, gap);

axes(ha(1)); hold on;
plot(wavelengths, backgroundSPD, 'Color', 'k');
plot(wavelengths, combinedSPD, 'Color', 'r');
xlabel('Wavelength (nm)');
ylabel('Radiance')
yticks([]);
pbaspect([1 1 1])
set(gca, 'FontSize', fontSize);
set(gca, 'FontName', 'Helvetica Neue');

axes(ha(2)); hold on;
[contrasts, excitations] = ToDesiredReceptorContrast(MaxLMSDirection, MaxLMSBackground, T_receptors);
b = bar([excitations(3,1) excitations(3,2); excitations(4,1) excitations(4,2); excitations(2,1), excitations(2,2); excitations(1,1), excitations(1,2)]);
b(1).FaceColor = 'k';
b(2).FaceColor = 'r';
xticklabels({'S Cone', 'Melanopsin', 'M Cone', 'L Cone'})
xlim([0 5]);
xtickangle(30)
ylabel('Receptor Excitations')
yticks([]);
pbaspect([1 1 1])
set(gca, 'FontSize', fontSize);
set(gca, 'FontName', 'Helvetica Neue');

export_fig(plotFig, fullfile(getpref('melSquintAnalysis', 'melaAnalysisPath'), 'melSquintAnalysis', 'OSAFigures', 'LMSFull.pdf'), '-painters');

%% Light Flux

combinedSPD = LightFluxDirection.ToPredictedSPD + LightFluxBackground.ToPredictedSPD + LightFluxBackground.calibration.computed.pr650MeanDark;
backgroundSPD =  LightFluxBackground.ToPredictedSPD + LightFluxBackground.calibration.computed.pr650MeanDark;
% just the background
plotFig = figure; hold on;
[ha, pos] = tight_subplot(1,2, gap);

axes(ha(1)); hold on;
plot(wavelengths, backgroundSPD, 'Color', 'k');
xlabel('Wavelength (nm)');
ylabel('Radiance')
yticks([]);
pbaspect([1 1 1])
set(gca, 'FontSize', fontSize);
set(gca, 'FontName', 'Helvetica Neue');

axes(ha(2)); hold on;
[contrasts, excitations] = ToDesiredReceptorContrast(LightFluxDirection, LightFluxBackground, T_receptors);
a = bar([excitations(3,1), excitations(4,1), excitations(2,1), excitations(1,1)], 'FaceColor', 'k');
a.BarWidth = 0.4;
xticklabels({'S Cone', 'Melanopsin', 'M Cone', 'L Cone'})
xlim([0 5]);
xtickangle(30)
ylabel('Receptor Excitations')
yticks([]);
pbaspect([1 1 1])
set(gca, 'FontSize', fontSize);
set(gca, 'FontName', 'Helvetica Neue');
export_fig(plotFig, fullfile(getpref('melSquintAnalysis', 'melaAnalysisPath'), 'melSquintAnalysis', 'OSAFigures', 'LightFluxBackground.pdf'), '-painters');


plotFig = figure; hold on;
[ha, pos] = tight_subplot(1,2, gap);

axes(ha(1)); hold on;
plot(wavelengths, backgroundSPD, 'Color', 'k');
plot(wavelengths, combinedSPD, 'Color', 'r');
xlabel('Wavelength (nm)');
ylabel('Radiance')
yticks([]);
pbaspect([1 1 1])
set(gca, 'FontSize', fontSize);
set(gca, 'FontName', 'Helvetica Neue');

axes(ha(2)); hold on;
[contrasts, excitations] = ToDesiredReceptorContrast(LightFluxDirection, LightFluxBackground, T_receptors);
b = bar([excitations(3,1) excitations(3,2); excitations(4,1) excitations(4,2); excitations(2,1), excitations(2,2); excitations(1,1), excitations(1,2)]);
b(1).FaceColor = 'k';
b(2).FaceColor = 'r';
xticklabels({'S Cone', 'Melanopsin', 'M Cone', 'L Cone'})
xlim([0 5]);
xtickangle(30)
ylabel('Receptor Excitations')
yticks([]);
pbaspect([1 1 1])
set(gca, 'FontSize', fontSize);
set(gca, 'FontName', 'Helvetica Neue');

export_fig(plotFig, fullfile(getpref('melSquintAnalysis', 'melaAnalysisPath'), 'melSquintAnalysis', 'OSAFigures', 'LightFluxFull.pdf'), '-painters');

