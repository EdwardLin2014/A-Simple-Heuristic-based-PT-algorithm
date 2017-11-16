function [ mXdB ] = PartialsTomXdB( Partials, Parm )
%   Partials: struct type
%   Parm: System configuration
%   return mXdB: a numBins*numFrames matrix, which only its peaks got
%   magnitude value in dB

mXdB = zeros(Parm.numBins, Parm.numFrames);
mXdB(:,:) = MagTodB(eps);

numPartials = numel(Partials);
for i = 1:numPartials
    Partial = Partials{i};
    for j = 1:Partial.size
        mXdB(Partial.freqIdx(j),Partial.period(1)+(j-1)) = Partial.mag(j);
    end
end

end

