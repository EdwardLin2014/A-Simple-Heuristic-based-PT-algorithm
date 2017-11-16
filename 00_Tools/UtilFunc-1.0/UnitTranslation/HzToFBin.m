function [ FBin ] = HzToFBin( Hz, Parm )

FBin = round(Parm.N/Parm.fs * Hz) + 1;

MaxFBin = floor(Parm.N/2)+1;
FBin(FBin<1) = 1;
FBin(FBin>MaxFBin) = MaxFBin;

end

