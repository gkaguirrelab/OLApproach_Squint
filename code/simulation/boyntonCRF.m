function response = boyntonCRF(contrastSupport, frequency)
%boyntonCRF - Contrast response values from Boynton & Heeger 1999
% Function Call:
%   response = boyntonCRF(contrastSupport, frequency)
%
% Usage: 
%   This function returns the contrast response values measured in the
%   Boynton & Heeger Vision Research 1999 paper. This is done for either a
%   0.5 or a 2.0 CPD stimulus used in the paper.
%
% Inputs: 
%   contrastSupport  = The contast value support for the CRF fit
%                      function. Either scalar or vector of contrast
%   frequency        = Pick the paramters for either 0.5 or 2.0 CPD
%                      numerical input of either 0.5 or 2.0.
%
% Outputs: 
%   response         = Contrast response values for V1 from Boynton & Heeger 1999 .

% mab 03/08/2017

% Set parameters

a = 1.16;
p = 0.40;
q = 1.40;
switch frequency 
    case 0.5
        sig = 2.56;
    case 2.0
        sig = 6.96;
end

% Equation 1 from Boynton & Heeger 1999
response = a .* ((contrastSupport.^(p+q)) ./ (contrastSupport.^q + sig.^q));

end
