function [ MagLevel ] = dBToMagLvl( dB, mindB, maxdB )

% Divide up the magnitude spectrogram into Magnitude Level
% Based on "How Color Axis Scaling Works" in Matlab
% https://www.mathworks.com/help/matlab/ref/caxis.html

Tlvl = 64;     % Default Total Level in Matlab

MagLevel = fix((dB-mindB)/(maxdB-mindB)*Tlvl)+1;
%Clamp values outside the range [1 m]
MagLevel(MagLevel<1) = 1;
MagLevel(MagLevel>Tlvl) = Tlvl; 

end

