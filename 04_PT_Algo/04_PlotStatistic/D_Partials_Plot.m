clear all; close all; clc

ToolDirStr = '../../00_Tools/';
DatabaseDirStr = '../../03_Database/iKala/Wavfile/';

% Choose song, 1-252
t = 221;
% Choose PT Algo - 1:FM, 2: SMS-PT, 3: MQ
PTAlgo = 3;
% Axis Configuration
StartHz = 0;
EndHz = 11025;
StartTimeSec = 0;
EndTimeSec = 30;
% Plot Config
FontSizeTitle = 20;
FontSizeAxis = 16;
FontSizeLabel = 20;
LegendFontSize = 16;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Step 0 - Addpath for SineModel/UtilFunc/BSS_Eval
addpath(genpath(ToolDirStr));
%% Step 0 - Parmaters Setting
% STFT
Parm.M = 1024;                  % Window Size, 46.44ms
Parm.window = hann(Parm.M);     % Window in Vector Form
Parm.N = 4096;                  % Analysis FFT Size, 185.76ms
Parm.H = 256;                   % Hop Size, 11.61ms
Parm.fs = 22050;                % Sampling Rate, 22.05K Hz
Parm.t = 42;                    % Dicard Peaks below Mag level 42
% PT algo
Parm.freqDevSlope = 0.01;       % Slope of the frequency deviation
Parm.freqDevOffset = 30;        % The minimum frequency deviation at 0 Hz
Parm.MagCond = 4;               % 4 dB for FM Algo
Parm.FreqCond = 20;             % 20 Hz dB for MQ Algo
Parm.minPartialLength = 4;      % Min Partial length, 4 peaks, 64.04ms
% Show Partials based on MagLvl
Parm.PlotMagLvl = 42;

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
% Spectrogram Dimension - Parm.numBins:2823 X Parm.numFrames:1874 = 5,290,302
[~, Voice.mX, ~, ~, ~, ~] = stft(Voice.x, Parm);
[~, Song.mX, ~, ~, ~, ~] = stft(Song.x, Parm);
[~, Mix.mX, Mix.pX, Parm.remain, Parm.numFrames, Parm.numBins] = stft(Mix.x, Parm);
Mix.mXdB = MagTodB(Mix.mX);
Parm.mindB = min(min(Mix.mXdB));
Parm.maxdB = max(max(Mix.mXdB));
if t <= 137
    AudioFileName = WavFileDirs{t}(end-14:end);
    AudioFileName = [AudioFileName(1:5),'\',AudioFileName(6:end)];
    fprintf('Import audio - %d:%s - needs %.2f sec\n', t, AudioFileName, toc);
else
    AudioFileName = WavFileDirs{t}(end-15:end);
    AudioFileName = [AudioFileName(1:5),'\',AudioFileName(6:end)];
    fprintf('Import audio - %d:%s - needs %.2f sec\n', t, AudioFileName, toc);
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
%% Step 3 - Create Sinusoidal Partials
tic
if PTAlgo == 1
    PTAlgoText = 'FM Algorithm';
    Partials = PT_Algo_FM_C( Mix.mXdB, Mix.ploc, Voice.IBMPeak, Parm );
elseif PTAlgo == 2
    PTAlgoText = 'SMS-PT Algorithm';
    Parm.freqDevOffset = 10;        % The minimum frequency deviation at 0 Hz
    Partials = PT_Algo_SMS_C( Mix.mXdB, Mix.ploc, Voice.IBMPeak, Parm );
else
    PTAlgoText = 'MQ Algorithm';
    Partials = PT_Algo_MQ_C( Mix.mXdB, Mix.ploc, Voice.IBMPeak, Parm );
end
fprintf('Create Sinusoidal Partials needs %.2f sec\n', toc);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Step 4 - Classify Sinusoidal Partials
tic
[ Voice.Partials, Song.Partials ] = ClassifyPartials( Partials );
fprintf('Classify Sinusoidal Partials need %.2f sec\n', toc);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Step 5 Visualization
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
figure('Color','w','units','normalized','outerposition',[0 0 1 1]);
colormap parula;
imagesc(T(TimeRange), F(HzRange), MagTodB(Mix.mX(HzRange,TimeRange)));
set(gca,'FontWeight','bold','FontSize', FontSizeAxis);
title([PTAlgoText, ' - ', AudioFileName],'FontSize', FontSizeTitle);
xlabel('Time (sec)','FontSize', FontSizeLabel);
ylabel('Frequency (Hz)','FontSize',FontSizeLabel);
set(gca,'YDir','normal');
set(gca,'XMinorTick','on','YMinorTick','on');
hold on;
PlotVoicePartials = PartialToPlot( Voice.Partials, Parm.numFrames, Parm.PlotMagLvl );
PlotSongPartials = PartialToPlot( Song.Partials, Parm.numFrames, Parm.PlotMagLvl );
p1 = plot(T(TimeRange), PlotVoicePartials(:,TimeRange), 'r');
p2 = plot(T(TimeRange), PlotSongPartials(:,TimeRange), 'k');
h = legend([p1(1) p2(1)],'Singing Voice Partials','Music Accompaniment Partials','Location','northoutside','Orientation','horizontal');
set(h,'FontWeight','bold','FontSize',LegendFontSize);
c = colorbar('Location', 'eastoutside');
c.Label.String = 'Magnitude (dB)';
c.Label.FontSize = FontSizeLabel;
c.Label.FontWeight = 'bold';