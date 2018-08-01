function [ newLuminance ] = predictNewLuminanceWhenChangingNDFilters(startingLuminance, magnitudeNDFilterChange)
% A simple function to predict what the luminance of a light source will be after changig the ND filter.
%
% Syntax:
%  [ newLuminance ] = predictNewLuminanceWhenChangingNDFilters(startingLuminance, magnitudeNDFilterChange)
%
% Inputs:
%   startingLuminance        - A number quantifying the initial intenisty of 
%                              the light source.
%   magnitudeNDFilterChange  - A number quantifying the change in ND filter.
%                              Positive values reflect adding more ND filter;
%                              negative values mean removing ND filter.
%
% Outputs:
%   newLuminance              - Predicted light intensity after change in ND
%                               filter, expressed in the same units as the
%                               startingLuminance



newLuminance = startingLuminance * 10^(-magnitudeNDFilterChange);

end