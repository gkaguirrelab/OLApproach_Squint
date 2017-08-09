function StimulationTimeAnalysis(responseStruct,varargin)
%%SimulationTimeAnalysis - Analyze the trial timing within an experiment run 
%
% Usage:
%    StimulationTimeAnalysis(responseStruct,varargin)
%
% Description:
%    The function will take in a responseStruct output from
%    TrialSequenceMRTrialLoop.m and 
%
%    The returned responseStruct says what happened on each trial.
%
% Input:
%    protocolParams (struct)  The protocol parameters structure.
%    block (struct)           Contains trial-by-trial starts/stops and other info.
%    ol (object)              An open OneLight object.
%
% Output:
%    responseStruct (struct)  Structure containing information about what happened on each trial 
%
% Optional key/value pairs:
%    verbose (logical)         true       Be chatty?

%% Parse input
p = inputParser;
p.addParameter('verbose',true,@islogical);
p.parse(varargin{:});