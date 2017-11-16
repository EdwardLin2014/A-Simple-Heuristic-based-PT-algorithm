function [ Hz ] = FBinToHz( FBin, Parm )

%       FBin: [0 ... N-1]
%    Parm.fs: sampling rate
%     Parm.N: DFT Size
MaxFBin = floor(Parm.N/2)+1;
FBin(FBin > MaxFBin) = MaxFBin;
FBin(FBin < 1) = 1;
Hz = Parm.fs/Parm.N * (FBin-1);

end

