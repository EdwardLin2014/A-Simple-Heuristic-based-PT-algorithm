function y = istft(mY, pY, Parm )
%% Synthesis of a sound using the short-time Fourier transform
%% Input:
%           mY: magnitude spectrogram,
%           pY: phase spectrogram,
%         Parm: STFT configuration,
%       Parm.M: window size,
%       Parm.N: DFT size (no constraint on power 2!),
%       Parm.H: hop size,
%       remain: audio signal between the center of last frame and the end of
%                   audio signal; for synthesis
%% Ouput:
%            y: output sound
if ~isfield(Parm, 'N');  N = 5644; else N = Parm.N; end
if ~isfield(Parm, 'M');  M = 1411; else M = Parm.M; end
if ~isfield(Parm, 'H');  H = 353; else H = Parm.H; end
if ~isfield(Parm, 'remain');  remain = 0; else remain = Parm.remain; end

% prepare istft looping
hM1 = floor((M+1)/2);                                         % half analysis window size by rounding
hM2 = floor(M/2);                                             % half analysis window size by floor
[~,numFrames] = size(mY);                                     % number of frames
y = zeros(hM2 + 1 + (numFrames-1)*H + remain + hM1, 1);       % initialize output array

%% run istft
% Note index diff for odd/even size of analysis window
pin = (hM2+1):H:(numel(y) - hM1);
t = 1;
if mod(hM2,2) == 1
    for i = pin
        ytmp = dftSynth(mY(:,t), pY(:,t), M, N);
        y(i-hM1+1:i+hM2) = y(i-hM1+1:i+hM2) + H.*ytmp;    % overlap-add to generate output sound
        t = t + 1;
    end
else
    for i = pin
        ytmp = dftSynth(mY(:,t), pY(:,t), M, N);
        y(i-hM1:i+hM2-1) = y(i-hM1:i+hM2-1) + H.*ytmp;    % overlap-add to generate output sound
        t = t + 1;
    end
end

% delete half of first window and half of the last window which was added in stft
y = y(hM2+1:end-hM1);
end
