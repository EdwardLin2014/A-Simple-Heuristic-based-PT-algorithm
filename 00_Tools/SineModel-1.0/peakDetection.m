function [ ploc ] = peakDetection( mXdB, Parm )
% Detect spectral peak locations
% mXdB: magnitude spectrum in dB
% t: MagLevel: 1-64
% returns mask of peak locations

ploc = zeros(Parm.numBins,Parm.numFrames);

for n=1:Parm.numFrames
    % potential location of peak
    [~, idx] = findpeaks(mXdB(:,n));
    ploc(idx,n) = 1;
    
    % peak below Mag Level, cancel
    [cancelrow,~] = find(dBToMagLvl(mXdB(idx,n), Parm.mindB, Parm.maxdB) < Parm.t);
    ploc(idx(cancelrow),n) = 0;
end

end

