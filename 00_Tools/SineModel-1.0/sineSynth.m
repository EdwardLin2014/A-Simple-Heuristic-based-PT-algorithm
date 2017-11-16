function y = sineSynth(mYdB, pY, ploc, Parm )
%% Synthesis of a sound using the short-time Fourier transform
%% Input:
%         mYdB: magnitude spectrogram in cell type
%           pY: phase spectrogram in cell type
%         ploc: frequency info - peak location in matrix type
%         Parm: STFT configuration,
%       Parm.M: window size,
%       Parm.N: DFT size (no constraint on power 2!),
%       Parm.H: hop size,
%       remain: audio signal between the center of last frame and the end of
%                   audio signal; for synthesis
%% Ouput:
%            y: output sound
if ~isfield(Parm, 'N');  N = 4096; else N = Parm.N; end
if ~isfield(Parm, 'M');  M = 1024; else M = Parm.M; end
if ~isfield(Parm, 'H');  H = 256; else H = Parm.H; end
if ~isfield(Parm, 'remain');  remain = 0; else remain = Parm.remain; end

%% prepare synthesis window
Ns = 1024;                           % FFT size for synthesis (eve)
hNs = 512;                           % half synthesis window size
sw = zeros(Ns,1);                    % initialize synthesis window
ow = triang(2*H);                    % overlapping window
ovidx = Ns/2+1-H+1:Ns/2+H;           % overlap indexes
sw(ovidx) = ow(1:2*H-1);
bh = blackmanharris(Ns);             % synthesis window
bh = bh ./ sum(bh);                  % normalize synthesis window
sw(ovidx) = sw(ovidx) ./ bh(ovidx);

%% prepare sineSynth looping
hM1 = floor((M+1)/2);                                         % half analysis window size by rounding
hM2 = floor(M/2);                                             % half analysis window size by floor
numFrames = Parm.numFrames;                                   % number of frames
y = zeros(hM2 + 1 + (numFrames-1)*H + remain + hM1, 1);       % initialize output array

%% run sineSynth
pin = (hM2+1):H:(numel(y) - hM1);
t = 1;
for i = pin
    sploc = (find(ploc(:,t))-1)*Ns/N;
    Y = genSpecSines_C( sploc, mYdB{t}, pY{t}, Ns );
    ytmp = fftshift(real(ifft(Y)));
    y(i-hNs:i+hNs-1) = y(i-hNs:i+hNs-1) + sw.*ytmp;       % overlap-add to generate output sound
    t = t + 1;
end

%% delete half of first window and half of the last window which was added in stft
y = y(hM2+1:end-hM1);
end
