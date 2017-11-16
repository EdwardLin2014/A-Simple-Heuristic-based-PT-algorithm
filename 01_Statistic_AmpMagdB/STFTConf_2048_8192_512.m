%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This script record the maximum and minimum amplitude of the signals
%       and the maximum and minimum magnitude value of the signals'
%       spectrogram, base on the STFT configuration
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all; close all; clc

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Step 0 - Parmaters Setting
ToolDirStr = '../00_Tools/';
DatabaseDirStr = '../Wavfile/';
% STFT
Parm.M = 2048;                  % Window Size, 92.88ms
Parm.window = hann(Parm.M);     % Window in Vector Form
Parm.N = 8192;                  % Analysis DFT Size, 371.52ms
Parm.H = 512;                   % Hop Size, 23.22ms
Parm.fs = 22050;                % Sampling Rate, 22.05K Hz
Parm.t = 1;                     % Need All Peaks, in term of Mag Level

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Step 0 - Addpath for SineModel/UtilFunc/BSS_Eval
addpath(genpath(ToolDirStr));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Step 0 - Obtain Audio File Name
WavFileNames = iKalaWavFileNames(DatabaseDirStr);
numMusics = numel(WavFileNames);
% Statistics - Magnitude
MixAmp = zeros(numMusics,2);
OverallMag = zeros(numMusics,2);
OverallMagdB = zeros(numMusics,2);

for t = 1:numMusics
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Step 1 - Import Audio and Create Power Spectrogram
    tic
    [x, ~] = audioread(WavFileNames{t});
    Mix.x = resample( (x(:,1)+x(:,2)), 1, 2);
    MixAmp(t,1) = min(Mix.x);
    MixAmp(t,2) = max(Mix.x);
    % Spectrogram Dimension - Parm.numBins:4097 X Parm.numFrames:1292 = 5,293,324
    [~, Mix.mX, ~, ~, ~, ~] = stft(Mix.x, Parm);
    OverallMag(t,1) = min(min(Mix.mX)); OverallMag(t,2) = max(max(Mix.mX));
    OverallMagdB(t,1) = MagTodB(min(min(Mix.mX))); OverallMagdB(t,2) = MagTodB(max(max(Mix.mX)));
    if t <= 137
        fprintf('Import audio - %d:%s - needs %.2f sec\n', t, WavFileNames{t}(end-14:end), toc);
    else
        fprintf('Import audio - %d:%s - needs %.2f sec\n', t, WavFileNames{t}(end-15:end), toc);
    end
end