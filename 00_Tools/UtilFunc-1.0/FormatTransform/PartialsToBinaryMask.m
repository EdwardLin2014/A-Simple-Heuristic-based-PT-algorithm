function [ ploc ] = PartialsToBinaryMask( Partials, Parm )
%% Transform Partials into a binary mask
%   Partials: struct type
%   Parm: System configuration
%   return ploc: peak location as a numBins*numFrames matrix

ploc = zeros(Parm.numBins, Parm.numFrames);

numPartials = numel(Partials);
for i = 1:numPartials
    Partial = Partials{i};
    for j = 1:Partial.size
        ploc(Partial.freqIdx(j),Partial.period(1)+(j-1)) = 1;
    end
end

end

