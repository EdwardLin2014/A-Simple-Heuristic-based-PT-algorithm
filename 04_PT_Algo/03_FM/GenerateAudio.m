%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This script generates audio 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all; close all; clc

ToolDirStr = '../../00_Tools/';
DatabaseDirStr = '../../Wavfile/';
AudioOutDirStr = '../../Audio/04_PT_Algo/';

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
Parm.binFreq = Parm.fs/Parm.N;  % Frequency of a Bin
Parm.freqDevSlope = 0.01;       % Slope of the frequency deviation
Parm.freqDevOffset = 30;        % The minimum frequency deviation at 0 Hz
Parm.MagCond = 4;               % 4 dB
Parm.minPartialLength = 4;      % Min Partial length, 4 peaks, 46.44ms

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
WavFileDirs = iKalaWavFileNames(DatabaseDirStr);
numMusics = numel(WavFileDirs);

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
    Partials = PT_Algo_FM_C( Mix.mXdB, Mix.ploc, Voice.ISP, Parm );
    fprintf('Create Sinusoidal Partials needs %.2f sec\n', toc);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Step 4 - Classify Sinusoidal Partial
    tic
    [ Voice.Partials, Song.Partials ] = ClassifyPartials( Partials );
    fprintf('Classify Sinusoidal Partials need %.2f sec\n', toc);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Step 5 - iSTFT/AddSynth
    tic
    mV = PartialsToBinaryMask( Voice.Partials, Parm ) .* Mix.mX;
    mV(mV<eps) = eps;
    mS = PartialsToBinaryMask( Song.Partials, Parm ) .* Mix.mX;
    mS(mS<eps) = eps;
    Voice.ISP_iSTFT_y = istft(mV, Mix.pX, Parm );
    Voice.ISP_iSTFT_y = resample(Voice.ISP_iSTFT_y,2,1);
    Voice.ISP_iSTFT_y = scaleAudio( Voice.ISP_iSTFT_y, MinAmp, MaxAmp );
    Song.ISP_iSTFT_y = istft(mS, Mix.pX, Parm );
    Song.ISP_iSTFT_y = resample(Song.ISP_iSTFT_y,2,1);
    Song.ISP_iSTFT_y = scaleAudio( Song.ISP_iSTFT_y, MinAmp, MaxAmp );
    
    Voice.PMask = PartialsToBinaryMask( Voice.Partials, Parm );
    mVdB = Voice.PMask .* Mix.mXdB;
    mVdB = prepareSineSynth( mVdB, Voice.PMask, Parm );
    pV = prepareSineSynth( Mix.pX, Voice.PMask, Parm );
    Song.PMask = PartialsToBinaryMask( Song.Partials, Parm );
    mSdB = Song.PMask .* Mix.mXdB;
    mSdB = prepareSineSynth( mSdB, Song.PMask, Parm );
    pS = prepareSineSynth( Mix.pX, Song.PMask, Parm );
    Voice.ISP_AS_y = sineSynth( mVdB, pV, Voice.PMask, Parm );
    Voice.ISP_AS_y = resample( Voice.ISP_AS_y,2,1 );
    Voice.ISP_AS_y = scaleAudio( Voice.ISP_AS_y, MinAmp, MaxAmp );
    Song.ISP_AS_y = sineSynth( mSdB, pS, Song.PMask, Parm );
    Song.ISP_AS_y = resample( Song.ISP_AS_y,2,1 );
    Song.ISP_AS_y = scaleAudio( Song.ISP_AS_y, MinAmp, MaxAmp );
    fprintf('Computing iSTFT/AddSynth need %.2f sec\n', toc);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Step 6 - genSound
    tic
    if t <= 137
        audiowrite([AudioOutDirStr, '/FM/iSTFT_1024_4096_256_42_001_30_4_4/Voice/',WavFileDirs{t}(end-14:end)], Voice.ISP_iSTFT_y, fs );
        audiowrite([AudioOutDirStr, '/FM/iSTFT_1024_4096_256_42_001_30_4_4/Song/',WavFileDirs{t}(end-14:end)], Song.ISP_iSTFT_y, fs );
        audiowrite([AudioOutDirStr, '/FM/AS_1024_4096_256_42_001_30_4_4/Voice/',WavFileDirs{t}(end-14:end)], Voice.ISP_AS_y, fs );
        audiowrite([AudioOutDirStr, '/FM/AS_1024_4096_256_42_001_30_4_4/Song/',WavFileDirs{t}(end-14:end)], Song.ISP_AS_y, fs );
    else
        audiowrite([AudioOutDirStr, '/FM/iSTFT_1024_4096_256_42_001_30_4_4/Voice/',WavFileDirs{t}(end-15:end)], Voice.ISP_iSTFT_y, fs );
        audiowrite([AudioOutDirStr, '/FM/iSTFT_1024_4096_256_42_001_30_4_4/Song/',WavFileDirs{t}(end-15:end)], Song.ISP_iSTFT_y, fs );
        audiowrite([AudioOutDirStr, '/FM/AS_1024_4096_256_42_001_30_4_4/Voice/',WavFileDirs{t}(end-15:end)], Voice.ISP_AS_y, fs );
        audiowrite([AudioOutDirStr, '/FM/AS_1024_4096_256_42_001_30_4_4/Song/',WavFileDirs{t}(end-15:end)], Song.ISP_AS_y, fs );
    end
    fprintf('genSound needs %.2f sec\n', toc);
    fprintf('=================================================\n');
end