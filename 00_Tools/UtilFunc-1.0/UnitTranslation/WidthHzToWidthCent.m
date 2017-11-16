function [ WidthCent ] = WidthHzToWidthCent( WidthHz, CentralFreq )

%   CentFreq in Hz

WidthCent = log2(WidthHz/CentralFreq+1)*1200;

end

