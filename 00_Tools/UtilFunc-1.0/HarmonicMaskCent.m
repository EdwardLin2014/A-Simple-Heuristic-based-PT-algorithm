function [ Mask ] = HarmonicMaskCent( VocalF0, mX, Parm )

numFrames = Parm.numFrames;
numBins = Parm.numBins;
N = Parm.N;
fs = Parm.fs;
HarmCent = Parm.HarmCent;

Mask = zeros(numBins, numFrames);
MaxFreq = fs/2;             %% Max Freq 11025Hz
MinFreq = fs/N;

for n = 1:numFrames
    h = 1;
    curFreq = h*VocalF0(n);
    while (curFreq < MaxFreq && curFreq > MinFreq)
        WidthHz = WidthCentToWidthHz( HarmCent, curFreq );
        
        UpperBin = HzToFBin( curFreq+WidthHz, Parm );
        LowerBin = HzToFBin( curFreq-WidthHz, Parm );
        
        range = LowerBin:UpperBin;
        [~,I] = max(mX(range,n));
        Mask(range(I),n) = 1;
        
        h = h + 1;
        curFreq = h*VocalF0(n);
    end
end
        
end