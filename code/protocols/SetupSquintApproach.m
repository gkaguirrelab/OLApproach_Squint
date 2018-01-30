%%SetupSquintAppraoch  Do the protocol indpendent steps required to run a squint protocol.
%
% Description:
%   Do the protocol indpendent steps required to run a protocol.  
%   These are:
%     Do the calibration (well, that doesn't happen here but you need to do it.)
%     Make the nominal background primaries.
%     Make the nominal direction primaries.

%% Parameters
%
% Who we are
approachParams.approach = 'OLApproach_Squint';

% List of all calibrations used in this approach
approachParams.calibrationTypes = {'BoxBRandomizedLongCableDStubby1_ND00', 'BoxARandomizedLongCableAEyePiece1_ND01'};

% List of all backgrounds used in this approach
approachParams.backgroundNames = {'MelanopsinDirected_275_60_667', 'LMSDirected_275_60_667'};

% List of all directions used in this approach
approachParams.directionNames = {'MaxMel_unipolar_275_60_667', 'MaxLMS_unipolar_275_60_667'};

%%  Make the backgrounds
for cc = 1:length(approachParams.calibrationTypes)
    tempApproachParams= approachParams;
    tempApproachParams.calibrationType = approachParams.calibrationTypes{cc};  
    OLMakeBackgroundNominalPrimaries(tempApproachParams);
end

%%  Make the directions
for cc = 1:length(approachParams.calibrationTypes)
    tempApproachParams = approachParams;
    tempApproachParams.calibrationType = approachParams.calibrationTypes{cc};  
    OLMakeDirectionNominalPrimaries(tempApproachParams,'verbose',false);
end

