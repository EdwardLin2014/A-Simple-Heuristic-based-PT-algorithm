%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This script plot ideal peaks for a song.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all; close all; clc

ToolDirStr = '../00_Tools/';
DatabaseDirStr = '../Wavfile/';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Step 0 - Addpath for SineModel/UtilFunc/BSS_Eval
addpath(genpath(ToolDirStr));
%% Step 0 - Parmaters Setting
% Choose song, 1-252
t = 252;
% STFT
Parm.M = 1024;                  % Window Size, 46.44ms
Parm.window = hann(Parm.M);     % Window in Vector Form
Parm.N = 4096;                  % Analysis FFT Size, 185.76ms
Parm.H = 256;                   % Hop Size, 11.61ms
Parm.fs = 22050;                % Sampling Rate, 22.05K Hz
Parm.t = 42;                    % Dicard Peaks below Mag level 42
% Axis Configuration 
StartHz = 0;
EndHz = 11025/4;
StartTimeSec = 0;
EndTimeSec = 30/6;
% Peak Ploc Marker Size
sz = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Step 0 - Obtain Audio File Name
WavFileDirs = iKalaWavFileNames(DatabaseDirStr);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Step 1 - Import Audio
tic
[x, ~] = audioread(WavFileDirs{t});
Mix.x = x(:,1) + x(:,2);
Mix.x = resample(Mix.x,1,2);
Voice.x = resample(x(:,2),1,2);
Song.x = resample(x(:,1),1,2);
% Spectrogram Dimension - Parm.numBins:2049 X Parm.numFrames:2584 = 5,294,616
[~, Voice.mX, ~, ~, ~, ~] = stft(Voice.x, Parm);
[~, Song.mX, ~, ~, ~, ~] = stft(Song.x, Parm);
[~, Mix.mX, Mix.pX, Parm.remain, Parm.numFrames, Parm.numBins] = stft(Mix.x, Parm);
Mix.mXdB = MagTodB(Mix.mX);
Parm.mindB = min(min(Mix.mXdB));
Parm.maxdB = max(max(Mix.mXdB));
if t <= 137
    fprintf('Import audio - %d:%s - needs %.2f sec\n', t, WavFileDirs{t}(end-14:end), toc);
else
    fprintf('Import audio - %d:%s - needs %.2f sec\n', t, WavFileDirs{t}(end-15:end), toc);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Step 2 - Find Ideal Binary Mask (IBM) and Ideal Spectral Peaks
tic
Voice.IBM = Voice.mX > Song.mX;
Song.IBM = Voice.mX <= Song.mX;
Mix.ploc = peakDetection( Mix.mXdB, Parm );
Voice.IBMPeak = Voice.IBM .* Mix.ploc;
Song.IBMPeak = Song.IBM .* Mix.ploc;
fprintf('Find IBM needs %.2f sec\n', toc);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Step 3 Visualization
%% Setup Axis
F = 0:Parm.fs/Parm.N:Parm.fs/2;
dt = Parm.H/Parm.fs;
songDur = length(Mix.x)/Parm.fs;
T = 0:dt:songDur;
%% Setup Plot Range
StartTIdx = find(T<StartTimeSec,1,'last');
EndTIdx = find(T>EndTimeSec,1);
if isempty(StartTIdx) || StartTIdx<1
    StartTIdx = 1;
end
if isempty(EndTIdx) || EndTIdx>Parm.numFrames
    EndTIdx = Parm.numFrames;
end
TimeRange = StartTIdx:EndTIdx;

StartFBin = HzToFBin(StartHz, Parm);
EndFBin = HzToFBin(EndHz, Parm);
HzRange = StartFBin:EndFBin;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Plot
figure('units','normalized','outerposition',[0 0 1 1]);
%colormap gray;

subplot(3,2,1);
imagesc(T(TimeRange), F(HzRange), Mix.mXdB(HzRange,TimeRange)), title('Mix - mX');
xlabel('Time (sec)'); ylabel('Frequency (Hz)');
set(gca,'YDir','normal');
set(gca,'XMinorTick','on','YMinorTick','on');

subplot(3,2,2);
imagesc(T(TimeRange), F(HzRange), Mix.mXdB(HzRange,TimeRange)), title('Mix - ploc (Peak Location)');
xlabel('Time (sec)'); ylabel('Frequency (Hz)');
set(gca,'YDir','normal');
set(gca,'XMinorTick','on','YMinorTick','on');
hold on;
[col,row] = find(Mix.ploc(HzRange,TimeRange)==1);
scatter(T(row),F(col),sz,'r');

subplot(3,2,3);
imagesc(T(TimeRange), F(HzRange), MagTodB(Voice.mX(HzRange,TimeRange))), title('Groud Truth Voice - mX');
xlabel('Time (sec)'); ylabel('Frequency (Hz)');
set(gca,'YDir','normal');
set(gca,'XMinorTick','on','YMinorTick','on');

subplot(3,2,4);
imagesc(T(TimeRange), F(HzRange), Mix.mXdB(HzRange,TimeRange)), title('Voice - Ideal Spectral Peaks; Background - Mix.mX');
xlabel('Time (sec)'); ylabel('Frequency (Hz)');
set(gca,'YDir','normal');
set(gca,'XMinorTick','on','YMinorTick','on');
hold on;
[col,row] = find(Voice.IBMPeak(HzRange,TimeRange)==1);
scatter(T(row),F(col),sz,'r');

subplot(3,2,5);
imagesc(T(TimeRange), F(HzRange), MagTodB(Song.mX(HzRange,TimeRange))), title('Ground Truth Song - mX');
xlabel('Time (sec)'); ylabel('Frequency (Hz)');
set(gca,'YDir','normal');
set(gca,'XMinorTick','on','YMinorTick','on');

subplot(3,2,6);
imagesc(T(TimeRange), F(HzRange), Mix.mXdB(HzRange,TimeRange)), title('Song - Ideal Spectral Peaks; Background - Mix.mX');
xlabel('Time (sec)'); ylabel('Frequency (Hz)');
set(gca,'YDir','normal');
set(gca,'XMinorTick','on','YMinorTick','on');
hold on;
[col,row] = find(Song.IBMPeak(HzRange,TimeRange)==1);
scatter(T(row),F(col),sz,'r');
