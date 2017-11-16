%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This script caculate the statistic of partials, Vibrato/Tremolo
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all; close all; clc

ToolDirStr = '../../00_Tools/';
DatabaseDirStr = '../../03_Database/iKala/Wavfile/';

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
%% PT algo
Parm.FreqCond = 20;                         % 20 Hz dB
Parm.minPartialLength = 4;                  % Min Partial length, 4 peaks, 64.04ms
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

VoicePartialVibTre = zeros(numMusics, 25*24);
SongPartialVibTre = zeros(numMusics, 25*24);

for t = 1:numMusics
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Step 1 - Import Audio and Create Power Spectrogram
    tic
    % import audio
    [x, fs] = audioread(WavFileDirs{t});
    Voice.x = resample(x(:,2),1,2);
    Song.x = resample(x(:,1),1,2);
    Mix.x = resample( (x(:,1)+x(:,2)), 1, 2);
    %% For Synthesize, constraint the amplitude to either the original max min, or [-1, 1]
    MinAmp = min(Mix.x); if MinAmp<-1; MinAmp = -1; end
    MaxAmp = max(Mix.x); if MaxAmp>1; MaxAmp = 1; end
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
    Partials = PT_Algo_MQ_C( Mix.mXdB, Mix.ploc, Voice.ISP, Parm );
    fprintf('Create Sinusoidal Partials needs %.2f sec\n', toc);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Step 4 - Classify Sinusoidal Partials
    [ Voice.Partials, Song.Partials ] = ClassifyPartials( Partials );
    fprintf('Classify Sinusoidal Partials need %.2f sec\n', toc);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Step 4 - Calculate Statistic of Partials Vibrato/Tremolo
    tic
    i = 1;
    [ Voice.vibrato, Voice.tremolo ] = PartialsVibTre( Voice.Partials, PParm );
    VoicePartialVibTre(t, (i-1)*25+1:(i-1)*25+15) = mean(Voice.vibrato);
    VoicePartialVibTre(t, (i-1)*25+16:(i-1)*25+25) = mean(Voice.tremolo);
    [ Song.vibrato, Song.tremolo ] = PartialsVibTre( Song.Partials, PParm );
    SongPartialVibTre(t, (i-1)*25+1:(i-1)*25+15) = mean(Song.vibrato);
    SongPartialVibTre(t, (i-1)*25+16:(i-1)*25+25) = mean(Song.tremolo);
    i = i + 1;
    for MagLvl = 64:-1:Parm.t
        PartialsAtMagLvl = GatherPartialsAtMagLvl( Voice.Partials, MagLvl );
        [ Voice.vibrato, Voice.tremolo ] = PartialsVibTre( PartialsAtMagLvl, PParm );
        VoicePartialVibTre(t, (i-1)*25+1:(i-1)*25+15) = mean(Voice.vibrato);
        VoicePartialVibTre(t, (i-1)*25+16:(i-1)*25+25) = mean(Voice.tremolo);
        
        PartialsAtMagLvl = GatherPartialsAtMagLvl( Song.Partials, MagLvl );
        [ Song.vibrato, Song.tremolo ] = PartialsVibTre( PartialsAtMagLvl, PParm );
        SongPartialVibTre(t, (i-1)*25+1:(i-1)*25+15) = mean(Song.vibrato);
        SongPartialVibTre(t, (i-1)*25+16:(i-1)*25+25) = mean(Song.tremolo);
        
        i = i + 1;
    end
    fprintf('Calculate Statistic of Partials Vibrato/Tremolo need %.2f sec\n', toc);
end

