function [ newLuminance ] = predictNewLuminanceWhenChangingNDFilters(startingLuminance, magnitudeNDFilterChange)

newLuminance = startingLuminance * 10^(-magnitudeNDFilterChange);

end