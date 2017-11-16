function [ X, mX, pX, remain, numFrames, numBins ] = stft(x, Parm )
%% Analysis of a sound using the short-time Fourier transform
%% Input:
%            x: audio signal,
%         Parm: STFT configuration,
%  Parm.window: analysis window (in term of vector)
%       Parm.M: window size,
%       Parm.N: DFT size (no constraint on power 2!),
%       Parm.H: hop size,
%% Ouput:
%            X: complex spectrogram,
%           mX: magnitude spectrogram,
%           pX: phase spectrogram,
%       remain: audio signal between the center of last frame and the end of
%                   audio signal; for synthesis
%    numFrames: number of frames,
%      numBins: number of bins
if ~isfield(Parm, 'window'); window = hann(1411); else window = Parm.window; end
if ~isfield(Parm, 'M'); M = length(window); else M = Parm.M; end
if ~isfield(Parm, 'N'); N = 5644; else N = Parm.N; end
if ~isfield(Parm, 'H'); H = 353; else H = Parm.H; end

% expect x as a column
if (size(x,2) > 1); x = x'; end

% prepare x
hM1 = floor((M+1)/2);             % half analysis window size by floor
hM2 = floor(M/2);                 % half analysis window size by floor
x = [zeros(hM2,1); x];            % add zeros at beginning to center first window at sample 0
x = [x; zeros(hM1,1)];            % add zeros at the end to analyze last sample

% prepare window
window = window / sum(window);    % normalize analysis window

% prepare stft looping
pin = (hM2+1):H:(numel(x) - hM1);
remain = numel(x) - hM1 - pin(end);

% prepare output
numFrames = numel(pin);
hN = floor(N/2)+1;                     % size of positive spectrum, it includes sample 0
numBins = hN;
X = zeros(hN, numFrames);
mX = zeros(hN, numFrames);
pX = zeros(hN, numFrames);

% Note index diff for odd/even size of analysis window
t = 1;
if mod(hM2,2) == 1
    for i = pin
        [X(:,t), mX(:,t), pX(:,t)] = dftAnal(x((i-hM1+1):i+hM2), N, window);
        t = t + 1;
    end
else
    for i = pin
        [X(:,t), mX(:,t), pX(:,t)] = dftAnal(x((i-hM1):i+hM2-1), N, window);
        t = t + 1;
    end
end

end
