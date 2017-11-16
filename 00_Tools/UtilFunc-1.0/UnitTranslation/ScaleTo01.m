function [ ScaledX ] = ScaleTo01( X )

OldMin = min(min(X));
OldMax = max(max(X));

ScaledFactor = 1./(OldMax-OldMin);
ScaledX = ScaledFactor.*(X - OldMin);

end