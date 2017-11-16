function [ Vibrato, Tremolo ] = PartialsVibTre( Partials, Parm )
%%
%   Convert Partial to its feature vector

NumOfPartials = numel(Partials);
% vibrato(1-5): statistic of vibrato freq in Hz
% vibrato(6-10): statistic of vibrato width in Hz
% vibrato(11-15): statistic of vibrato width in Cent
Vibrato = zeros(NumOfPartials,15);
% tremolo(1-5): statistic of tremolo freq in Hz
% tremolo(6-10): statistic of tremolo width in dB
Tremolo = zeros(NumOfPartials,10);

%% Do STFT
for i=1:NumOfPartials
    
    Partial = Partials{i};
    PFreqs = Partial.freq;
    PMags = Partial.mag;
    
    % vibrato
    CentralFreq = mean(PFreqs);
    zeroPFreqs = PFreqs - CentralFreq;
    [ ~, vib.mX, ~, ~, ~, ~ ] = stft( zeroPFreqs, Parm );
    % tremolo
    zeroPMags = PMags - mean(PMags);
    [ ~, tre.mX, ~, ~, numFrames, ~ ] = stft( zeroPMags, Parm );
    
    %% Calculate vibrato Freq and Ext
    vibratoFreq = zeros(numFrames,1);
    vibratoWidthHz = zeros(numFrames,1);
    vibratoWidthCent = zeros(numFrames,1);
    for n = 1:numFrames
        [vibratoWidthHz(n), vibratoFreq(n)] = max(vib.mX(:,n));
        vibratoFreq(n) = FBinToHz(vibratoFreq(n), Parm);
        if vibratoFreq(n) == 0
            vibratoWidthHz(n) = 0;
            vibratoWidthCent(n) = 0;
        else
            vibratoWidthHz(n) = vibratoWidthHz(n)*2;
            vibratoWidthCent(n) = WidthHzToWidthCent(vibratoWidthHz(n), CentralFreq);
        end
    end
    %% Calculate vibrato Freq and Ext
    tremoloFreq = zeros(numFrames,1);
    tremoloWidthdB = zeros(numFrames,1);
    for n = 1:numFrames
        [tremoloWidthdB(n), tremoloFreq(n)] = max(tre.mX(:,n));
        tremoloFreq(n) = FBinToHz(tremoloFreq(n), Parm);
        if tremoloFreq(n) == 0
            tremoloWidthdB(n) = 0;
        else
            tremoloWidthdB(n) = tremoloWidthdB(n)*2;
        end
    end
    
    %% Store vibrato data
    Vibrato(i,1) = mean(vibratoFreq);
    Vibrato(i,2) = std(vibratoFreq);
    Vibrato(i,3) = max(vibratoFreq);
    Vibrato(i,4) = min(vibratoFreq);
    Vibrato(i,5) = median(vibratoFreq);
    Vibrato(i,6) = mean(vibratoWidthHz);
    Vibrato(i,7) = std(vibratoWidthHz);
    Vibrato(i,8) = max(vibratoWidthHz);
    Vibrato(i,9) = min(vibratoWidthHz);
    Vibrato(i,10) = median(vibratoWidthHz);
    Vibrato(i,11) = mean(vibratoWidthCent);
    Vibrato(i,12) = std(vibratoWidthCent);
    Vibrato(i,13) = max(vibratoWidthCent);
    Vibrato(i,14) = min(vibratoWidthCent);
    Vibrato(i,15) = median(vibratoWidthCent);
    
    %% Store tremolo data
    Tremolo(i,1) = mean(tremoloFreq);
    Tremolo(i,2) = std(tremoloFreq);
    Tremolo(i,3) = max(tremoloFreq);
    Tremolo(i,4) = min(tremoloFreq);
    Tremolo(i,5) = median(tremoloFreq);
    Tremolo(i,6) = mean(tremoloWidthdB);
    Tremolo(i,7) = std(tremoloWidthdB);
    Tremolo(i,8) = max(tremoloWidthdB);
    Tremolo(i,9) = min(tremoloWidthdB);
    Tremolo(i,10) = median(tremoloWidthdB);

end

