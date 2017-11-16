function [ WidthHz ] = WidthCentToWidthHz( WidthCent, CentralFreq )

%   CentFreq in Hz

WidthHz = CentralFreq * (2^(WidthCent/1200)-1);

end

