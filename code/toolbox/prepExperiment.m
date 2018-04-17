function [ trialList ] = prepExperiment(protocolParams, varargin)


%% get information about the subject we're working with
commandwindow;
protocolParams.observerID = GetWithDefault('>> Enter <strong>observer name</strong>', 'HERO_xxxx');
protocolParams.observerAgeInYrs = GetWithDefault('>> Enter <strong>observer age</strong>:', 32);
protocolParams.sessionName = GetWithDefault('>> Enter <strong>session number</strong>:', 'session_1');
protocolParams.todayDate = datestr(now, 'yyyy-mm-dd');


%% Open the OneLight
ol = OneLight('simulate',protocolParams.simulate.oneLight,'plotWhenSimulating',protocolParams.simulate.makePlots); drawnow;

%% Let user get the radiometer set up
if ~protocolParams.simulate.radiometer
    radiometerPauseDuration = 0;
    ol.setAll(true);
    commandwindow;
    fprintf('- Focus the radiometer and press enter to pause %d seconds and start measuring.\n', radiometerPauseDuration);
    input('');
    ol.setAll(false);
    pause(radiometerPauseDuration);
    radiometer = OLOpenSpectroRadiometerObj('PR-670');
else
    radiometer = [];
end

%% open the session log
OLSessionLog(protocolParams,'OLSessionInit')

%% Make nominal direction objects, containing nominal primaries
