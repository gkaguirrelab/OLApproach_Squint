function [ luminance ] = calculateLuminance(backgroundSpectrum, S, luminanceType)

if strcmp(luminanceType, 'scotopic')
    load T_rods;
    T_vLambda = SplineCmf(S_rods,T_rods,S);
    magicFactor = 1700;
    luminance = T_vLambda * [backgroundSpectrum] * magicFactor;
    
end

if strcmp(luminanceType, 'photopic')
    
    load T_xyz1931
    T_xyz = SplineCmf(S_xyz1931,683*T_xyz1931,S);
    
    luminance = T_xyz(2,:) * [backgroundSpectrum];
    
end