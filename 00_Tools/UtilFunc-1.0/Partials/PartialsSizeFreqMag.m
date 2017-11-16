function [ Size,Freq,ZFreq,Mag,ZMag ] = PartialsSizeFreqMag( Partials )
%%
%   Convert Partial to its feature vector
NumOfPartials = numel(Partials);

Size = zeros(NumOfPartials,1);
Freq = zeros(NumOfPartials,5);      % Statistic of Freq
ZFreq = zeros(NumOfPartials,4);     % Statistic of zero-centered Freq
Mag = zeros(NumOfPartials,5);       % Statistic of Mag
ZMag = zeros(NumOfPartials,4);      % Statistic of zero-centered Mag

for i = 1:NumOfPartials
    Partial = Partials{i};
    zeroPFreqs = Partial.freq - mean(Partial.freq);
    zeroPMags = Partial.mag - mean(Partial.mag);
    
    Size(i,1) = Partial.size;
    Freq(i,1) = mean(Partial.freq);
    Freq(i,2) = std(Partial.freq);
    Freq(i,3) = max(Partial.freq);
    Freq(i,4) = min(Partial.freq);
    Freq(i,5) = median(Partial.freq);
    ZFreq(i,1) = std(zeroPFreqs);
    ZFreq(i,2) = max(zeroPFreqs);
    ZFreq(i,3) = min(zeroPFreqs);
    ZFreq(i,4) = median(zeroPFreqs);
    Mag(i,1) = mean(Partial.mag);
    Mag(i,2) = std(Partial.mag);
    Mag(i,3) = max(Partial.mag);
    Mag(i,4) = min(Partial.mag);
    Mag(i,5) = median(Partial.mag);
    ZMag(i,1) = std(zeroPMags);
    ZMag(i,2) = max(zeroPMags);
    ZMag(i,3) = min(zeroPMags);
    ZMag(i,4) = median(zeroPMags);
end

end
