function [ dB ] = MagTodB( Mag )

%% if zeros add epsilon(eps) to handle log
% The smallest representable number such that 1.0 + eps != 1.0.
% This code should not be executed?
Mag(Mag<eps) = eps;

dB = 20.*log10(Mag);

end
