function [ cX ] = prepareSineSynth( X, ploc, Parm )
%%
%   X: numBins*numFrames matrix, e.g. mX, pX
%   ploc: peak location
%   Parm: system configuration
%   retrun cX: cell(1,numFrames)

numFrames = Parm.numFrames;
cX = cell(1,numFrames);

for n = 1:numFrames
    cX{n} = X((ploc(:,n)==1),n);
end

end

