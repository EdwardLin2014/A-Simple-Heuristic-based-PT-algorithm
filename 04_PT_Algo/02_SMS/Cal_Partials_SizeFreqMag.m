%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This script caculate the statistic of partials, Size/Frequency/Magnitude
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all; close all; clc

ToolDirStr = '../../00_Tools/';
DatabaseDirStr = '../../Wavfile/';

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
Parm.freqDevSlope = 0.01;                   % Slope of the frequency deviation
Parm.freqDevOffset = 10;                    % The minimum frequency deviation at 0 Hz
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

NumFeatures = 23;
VoicePartialSFM = zeros(numMusics, NumFeatures*24);
SongPartialSFM = zeros(numMusics, NumFeatures*24);

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
    Partials = PT_Algo_SMS_C( Mix.mXdB, Mix.ploc, Voice.ISP, Parm );
    fprintf('Create Sinusoidal Partials needs %.2f sec\n', toc);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Step 4 - Classify Sinusoidal Partials
    [ Voice.Partials, Song.Partials ] = ClassifyPartials( Partials );
    fprintf('Classify Sinusoidal Partials need %.2f sec\n', toc);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Step 5 - Calculate Statistic of Partials Size Freq Mag
    tic
    i = 1;
    [ Size,Freq,ZFreq,Mag,ZMag ] = PartialsSizeFreqMag( Voice.Partials );
    VoicePartialSFM(t,(i-1)*NumFeatures+1) = mean(Size);
    VoicePartialSFM(t,(i-1)*NumFeatures+2) = std(Size);
    VoicePartialSFM(t,(i-1)*NumFeatures+3) = max(Size);
    VoicePartialSFM(t,(i-1)*NumFeatures+4) = min(Size);
    VoicePartialSFM(t,(i-1)*NumFeatures+5) = median(Size);
    VoicePartialSFM(t,(i-1)*NumFeatures+6:(i-1)*NumFeatures+10) = mean(Freq);
    VoicePartialSFM(t,(i-1)*NumFeatures+11:(i-1)*NumFeatures+14) = mean(ZFreq);
    VoicePartialSFM(t,(i-1)*NumFeatures+15:(i-1)*NumFeatures+19) = mean(Mag);
    VoicePartialSFM(t,(i-1)*NumFeatures+20:(i-1)*NumFeatures+23) = mean(ZMag);
    [ Size,Freq,ZFreq,Mag,ZMag ] = PartialsSizeFreqMag( Song.Partials );
    SongPartialSFM(t,(i-1)*NumFeatures+1) = mean(Size);
    SongPartialSFM(t,(i-1)*NumFeatures+2) = std(Size);
    SongPartialSFM(t,(i-1)*NumFeatures+3) = max(Size);
    SongPartialSFM(t,(i-1)*NumFeatures+4) = min(Size);
    SongPartialSFM(t,(i-1)*NumFeatures+5) = median(Size);
    SongPartialSFM(t,(i-1)*NumFeatures+6:(i-1)*NumFeatures+10) = mean(Freq);
    SongPartialSFM(t,(i-1)*NumFeatures+11:(i-1)*NumFeatures+14) = mean(ZFreq);
    SongPartialSFM(t,(i-1)*NumFeatures+15:(i-1)*NumFeatures+19) = mean(Mag);
    SongPartialSFM(t,(i-1)*NumFeatures+20:(i-1)*NumFeatures+23) = mean(ZMag);
    i = i + 1;
    for MagLvl = 64:-1:Parm.t
        PartialsAtMagLvl = GatherPartialsAtMagLvl( Voice.Partials, MagLvl );
        if isempty(PartialsAtMagLvl)
            VoicePartialSFM(t,(i-1)*NumFeatures+1:(i-1)*NumFeatures+23) = NaN;
        else
            [ Size,Freq,ZFreq,Mag,ZMag ] = PartialsSizeFreqMag( PartialsAtMagLvl );
            VoicePartialSFM(t,(i-1)*NumFeatures+1) = mean(Size);
            VoicePartialSFM(t,(i-1)*NumFeatures+2) = std(Size);
            VoicePartialSFM(t,(i-1)*NumFeatures+3) = max(Size);
            VoicePartialSFM(t,(i-1)*NumFeatures+4) = min(Size);
            VoicePartialSFM(t,(i-1)*NumFeatures+5) = median(Size);
            VoicePartialSFM(t,(i-1)*NumFeatures+6:(i-1)*NumFeatures+10) = mean(Freq);
            VoicePartialSFM(t,(i-1)*NumFeatures+11:(i-1)*NumFeatures+14) = mean(ZFreq);
            VoicePartialSFM(t,(i-1)*NumFeatures+15:(i-1)*NumFeatures+19) = mean(Mag);
            VoicePartialSFM(t,(i-1)*NumFeatures+20:(i-1)*NumFeatures+23) = mean(ZMag);
        end
        
        PartialsAtMagLvl = GatherPartialsAtMagLvl( Song.Partials, MagLvl );
        if isempty(PartialsAtMagLvl)
            SongPartialSFM(t,(i-1)*NumFeatures+1:(i-1)*NumFeatures+23) = NaN;
        else
            [ Size,Freq,ZFreq,Mag,ZMag ] = PartialsSizeFreqMag( PartialsAtMagLvl );
            SongPartialSFM(t,(i-1)*NumFeatures+1) = mean(Size);
            SongPartialSFM(t,(i-1)*NumFeatures+2) = std(Size);
            SongPartialSFM(t,(i-1)*NumFeatures+3) = max(Size);
            SongPartialSFM(t,(i-1)*NumFeatures+4) = min(Size);
            SongPartialSFM(t,(i-1)*NumFeatures+5) = median(Size);
            SongPartialSFM(t,(i-1)*NumFeatures+6:(i-1)*NumFeatures+10) = mean(Freq);
            SongPartialSFM(t,(i-1)*NumFeatures+11:(i-1)*NumFeatures+14) = mean(ZFreq);
            SongPartialSFM(t,(i-1)*NumFeatures+15:(i-1)*NumFeatures+19) = mean(Mag);
            SongPartialSFM(t,(i-1)*NumFeatures+20:(i-1)*NumFeatures+23) = mean(ZMag);
        end
        i = i + 1;
    end
    fprintf('Calculate Statistic of Partials Size,Freq, Mag need %.2f sec\n', toc);
end
