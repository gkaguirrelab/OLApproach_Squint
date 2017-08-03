function response = nakaRushton(contrastSupport,K,n,Rmax, offset)
%nakaRushton - Simulate contrast response values that follow a the naka rushton curve
%
% Function Call:
%   response = nakaRushton(contrastSupport,K,n,Rmax, offset)
%
% Usage: 
%   This function returns simutlated values of a contrast response function
%   as estimated by the Naka Rushton function. Rmax controls the "percent
%   signal change", K is the The semisaturation constant, and n controls
%   the slope. 
%
% Inputs: 
%   contrastSupport  = The contast value support for the naka rushton
%                      function. Either scalar or vector of contrast
%                      values.
%   K                = The semisaturation constant. 
%   n                = Controls the slope of the function. 
%   Rmax             = Maximun response value.
%   offset           = Function amplitude offset.
%
% Outputs: 
%   response         = Simulated response to the contrast values.

% mab 03/08/2017

% Naka-Rushton Function
response = Rmax .* ( contrastSupport.^n ./ (contrastSupport.^n + K.^n)) + offset;

end
