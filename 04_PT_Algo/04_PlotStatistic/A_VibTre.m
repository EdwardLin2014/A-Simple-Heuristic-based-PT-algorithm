clear all; close all; clc

ToolDirStr = '../../00_Tools/';
DatabaseDirStr = '../../Wavfile/';

% Features(1): Partial Size
% Features(2-6): Statistic of Freq
% Features(7-10): Statistic of zero-centered Freq
% Features(11-15): Statistic of Mag
% Features(16-19): Statistic of zero-centered Mag
% Features(20-24): statistic of vibrato freq in Hz
% Features(25-29): statistic of vibrato width in Hz
% Features(30-34): statistic of vibrato width in Cent
% Features(35-39): statistic of tremolo freq in Hz
% Features(40-44): statistic of tremolo width in dB
xF = 20;
yF = 25;
t = 149;                      % Choose Song 1 -252
MagLvl = 60;                  % Partials At Magnitude Level
xLabelStr = 'Normalized Vibrato Frequency';
yLabelStr = {'Normalized','Vibrato Width'};
FontSizeTitle = 20;
FontSizeAxis = 16;
FontSizeLabel = 20;
LegendFontSize = 16;
MarkerSize = 70;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Step 0 - Addpath for SineModel/UtilFunc/BSS_Eval
addpath(genpath(ToolDirStr));
%% Step 0 - Parmaters Setting
%% STFT
Parm.M = 1024;                              % Window Size, 46.44ms
Parm.window = hann(Parm.M);                 % Window in Vector Form
Parm.N = 4096;                              % Analysis FFT Size, 185.76ms
Parm.H = 256;                               % Hop Size, 11.61ms
Parm.fs = 22050;                            % Sampling Rate, 22.05K Hz
Parm.t = 42;                                % Dicard Peaks below Mag level 42
%% STFT Parm - Partial
PParm.fs = Parm.fs/Parm.H;                  % Sampling rate, 86.13 Hz
PParm.H = 1;                                % Hop size, 1 sample, 11.61ms
PParm.N = 2^(nextpow2(PParm.fs));           % FFT size, 128 samples, 1486.08 ms, 1Hz resolution wanted
PParm.M = PParm.N/4;                        % Window Size, 371.52 ms, 4 times zero padding
PParm.window = hann(PParm.M);               % Window in Vector Form
PParm.dt = 1/PParm.fs;                      % Time Resolution, 11.61ms
PParm.df = PParm.fs/PParm.N;                % Bin Frequency, 0.67 Hz
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
WavFileDirs = iKalaWavFileNames(DatabaseDirStr);
numMusics = numel(WavFileDirs);

%% PT algo
Parm.freqDevSlope = 0.01;                   % Slope of the frequency deviation
Parm.freqDevOffset = 30;                    % The minimum frequency deviation at 0 Hz
Parm.MagCond = 4;                           % 4 dB
Parm.minPartialLength = 4;                  % Min Partial length, 4 peaks, 46.44ms
%% MQ algo
Parm.FreqCond = 20;                         % 20 Hz dB

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Step 1 - Import Audio and Create Power Spectrogram
tic
% import audio
[x, fs] = audioread(WavFileDirs{t});
Voice.x = resample(x(:,2),1,2);
Song.x = resample(x(:,1),1,2);
Mix.x = resample( (x(:,1)+x(:,2)), 1, 2);
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
%% Step 2 - Create Ideal Spectral Peaks
tic
Voice.IBM = Voice.mX > Song.mX;
Song.IBM = Voice.mX <= Song.mX;
Mix.ploc = peakDetection( Mix.mXdB, Parm );
Voice.ISP = Voice.IBM .* Mix.ploc;
Song.ISP = Song.IBM .* Mix.ploc;
fprintf('Create Ideal Spectral Peaks needs %.2f sec\n', toc);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Step 3 - Create Sinusoidal Partials
tic
FMPartials = PT_Algo_FM_C( Mix.mXdB, Mix.ploc, Voice.ISP, Parm );
Parm.freqDevOffset = 10;                    % Change for SMS
SMSPartials = PT_Algo_SMS_C( Mix.mXdB, Mix.ploc, Voice.ISP, Parm );
MQPartials = PT_Algo_MQ_C( Mix.mXdB, Mix.ploc, Voice.ISP, Parm );
fprintf('Create Sinusoidal Partials needs %.2f sec\n', toc);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Step 4 - Classify Sinusoidal Partials
tic
[ Voice.FM.Partials, Song.FM.Partials ] = ClassifyPartials( FMPartials );
[ Voice.SMS.Partials, Song.SMS.Partials ] = ClassifyPartials( SMSPartials );
[ Voice.MQ.Partials, Song.MQ.Partials ] = ClassifyPartials( MQPartials );
fprintf('Classify Sinusoidal Partials need %.2f sec\n', toc);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Step 5 - Calculate Partials Features
tic
PartialsAtMagLvl = GatherPartialsAtMagLvl( Voice.FM.Partials, MagLvl );
Voice.FM.Features = PartialsFeatures( PartialsAtMagLvl, PParm );
PartialsAtMagLvl = GatherPartialsAtMagLvl( Song.FM.Partials, MagLvl );
Song.FM.Features = PartialsFeatures( PartialsAtMagLvl, PParm );

PartialsAtMagLvl = GatherPartialsAtMagLvl( Voice.SMS.Partials, MagLvl );
Voice.SMS.Features = PartialsFeatures( PartialsAtMagLvl, PParm );
PartialsAtMagLvl = GatherPartialsAtMagLvl( Song.SMS.Partials, MagLvl );
Song.SMS.Features = PartialsFeatures( PartialsAtMagLvl, PParm );

PartialsAtMagLvl = GatherPartialsAtMagLvl( Voice.MQ.Partials, MagLvl );
Voice.MQ.Features = PartialsFeatures( PartialsAtMagLvl, PParm );
PartialsAtMagLvl = GatherPartialsAtMagLvl( Song.MQ.Partials, MagLvl );
Song.MQ.Features = PartialsFeatures( PartialsAtMagLvl, PParm );

fprintf('Calculate Partials Features need %.2f sec\n', toc);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Step 6 - Normalized Partials Features
tic
[ Voice.FM.NorFeatures, Song.FM.NorFeatures, ~, ~ ] = NormalizedFeatures( Voice.FM.Features, Song.FM.Features );
[ Voice.SMS.NorFeatures, Song.SMS.NorFeatures, ~, ~ ] = NormalizedFeatures( Voice.SMS.Features, Song.SMS.Features );
[ Voice.MQ.NorFeatures, Song.MQ.NorFeatures, ~, ~ ] = NormalizedFeatures( Voice.MQ.Features, Song.MQ.Features );
fprintf('Normalized Partials Features need %.2f sec\n', toc);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Step 7 - Visualization
figure('Color', 'w', 'units','normalized','outerposition',[0 0 1 1]);
subplot(3,1,1);
scatter(Voice.FM.NorFeatures(:,xF),Voice.FM.NorFeatures(:,yF),MarkerSize,'+b');
hold on;
scatter(Song.FM.NorFeatures(:,xF),Song.FM.NorFeatures(:,yF),MarkerSize,'or');
ylim(gca,[-1,1]);
xlim(gca,[-1,1]);
set(gca,'XMinorTick','on','XGrid','on','YMinorTick','on','YGrid','on','FontWeight','bold','FontSize', FontSizeAxis);
title('(a) FM Algorithm','FontWeight','bold','FontSize', FontSizeTitle);
ylabel(yLabelStr,'FontWeight','bold','FontSize',FontSizeLabel);
h = legend('Singing Voice Partials','Music Accompaniment Partials','Location','northeast','Orientation','horizontal');
set(h,'FontWeight','bold','FontSize',LegendFontSize);

subplot(3,1,2);
scatter(Voice.SMS.NorFeatures(:,xF), Voice.SMS.NorFeatures(:,yF),MarkerSize,'+b');
hold on;
scatter(Song.SMS.NorFeatures(:,xF), Song.SMS.NorFeatures(:,yF),MarkerSize,'or');
ylim(gca,[-1,1]);
xlim(gca,[-1,1]);
set(gca,'XMinorTick','on','XGrid','on','YMinorTick','on','YGrid','on','FontWeight','bold','FontSize', FontSizeAxis);
title('(b) SMS-PT Algorithm','FontWeight','bold','FontSize', FontSizeTitle);
ylabel(yLabelStr,'FontWeight','bold','FontSize',FontSizeLabel);
h = legend('Singing Voice Partials','Music Accompaniment Partials','Location','northeast','Orientation','horizontal');
set(h,'FontWeight','bold','FontSize',LegendFontSize);

subplot(3,1,3);
scatter(Voice.MQ.NorFeatures(:,xF), Voice.MQ.NorFeatures(:,yF),MarkerSize,'+b');
hold on;
scatter(Song.MQ.NorFeatures(:,xF), Song.MQ.NorFeatures(:,yF),MarkerSize,'or');
ylim(gca,[-1,1]);
xlim(gca,[-1,1]);
set(gca,'XMinorTick','on','XGrid','on','YMinorTick','on','YGrid','on','FontWeight','bold','FontSize', FontSizeAxis);
title('(c) MQ Algorithm','FontWeight','bold','FontSize', FontSizeTitle);
ylabel(yLabelStr,'FontWeight','bold','FontSize',FontSizeLabel);
xlabel(xLabelStr,'FontWeight','bold','FontSize',FontSizeLabel);
h = legend('Singing Voice Partials','Music Accompaniment Partials','Location','northeast','Orientation','horizontal');
set(h,'FontWeight','bold','FontSize',LegendFontSize);
