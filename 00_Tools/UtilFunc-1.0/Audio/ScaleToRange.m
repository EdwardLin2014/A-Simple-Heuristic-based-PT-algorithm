function [ ScaledX ] = ScaleToRange( NewMin, NewMax, X )

OldMin = min(X);
OldMax = max(X);

ScaledFactor = (NewMax-NewMin)/(OldMax-OldMin);
ScaledX = ScaledFactor*(X - OldMin) + NewMin;

end

