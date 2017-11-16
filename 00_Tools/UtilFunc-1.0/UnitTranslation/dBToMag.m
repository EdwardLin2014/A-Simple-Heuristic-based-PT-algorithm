function [ Mag ] = dBToMag( dB )

Mag = 10.^(dB./20);

%% if zeros add epsilon(eps) to handle log
% The smallest representable number such that 1.0 + eps != 1.0.
Mag(Mag<eps) = eps;

end
