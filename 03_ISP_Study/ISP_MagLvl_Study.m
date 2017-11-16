%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This script studies how much ideal peak we can filter out and the BSS
%   score is not greatly affected, by setting 64 magnitude level.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all; close all; clc

ToolDirStr = '../00_Tools/';
DatabaseDirStr = '../Wavfile/';

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Step 0 - Obtain Audio File Name
WavFileDirs = iKalaWavFileNames(DatabaseDirStr);
numMusics = numel(WavFileDirs);
NumPeaks = zeros(numMusics,64*3);
ISP_iSTFT_BSS = zeros(numMusics,64*6);
ISP_AS_BSS = zeros(numMusics,64*6);

for t = 1:numMusics
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Step 1 - Import Audio and Create Power Spectrogram
    tic
    % import audio
    [x, ~] = audioread(WavFileDirs{t});
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
    %% Step 2 - Create Ideal Binary Mask
    tic
    Voice.IBM = Voice.mX > Song.mX;
    Song.IBM = Voice.mX <= Song.mX;
    fprintf('Create IBM needs %.2f sec\n', toc);
    
    for l = 1:64
        tic
        Parm.t = l;
        Mix.ploc = peakDetection( Mix.mXdB, Parm );
        Voice.ISP = Voice.IBM .* Mix.ploc;
        Song.ISP = Song.IBM .* Mix.ploc;
        fprintf('%d: Create IBM Peak needs %.2f sec\n', l, toc);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Step 3 - Peak Statistic
        tic
        NumPeaks(t,(l*3)-2) = numel(find(Mix.ploc == 1));
        NumPeaks(t,(l*3)-1) = numel(find(Voice.ISP == 1));
        NumPeaks(t,l*3) = numel(find(Song.ISP == 1));
        fprintf('%d: Peak Statistic needs %.2f sec\n', l, toc);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Step 4 - Synthesis
        tic
        mV = Voice.ISP .* Mix.mX;
        mV(mV<eps) = eps;
        mS = Song.ISP .* Mix.mX;
        mS(mS<eps) = eps;
        Voice.ISP_iSTFT_y = istft(mV, Mix.pX, Parm );
        Voice.ISP_iSTFT_y = resample(Voice.ISP_iSTFT_y,2,1);
        Voice.ISP_iSTFT_y = scaleAudio( Voice.ISP_iSTFT_y, MinAmp, MaxAmp );
        Song.ISP_iSTFT_y = istft(mS, Mix.pX, Parm );
        Song.ISP_iSTFT_y = resample(Song.ISP_iSTFT_y,2,1);
        Song.ISP_iSTFT_y = scaleAudio( Song.ISP_iSTFT_y, MinAmp, MaxAmp );
        
        mVdB = Voice.ISP .* Mix.mXdB;
        mVdB = prepareSineSynth( mVdB, Voice.ISP, Parm );
        pV = prepareSineSynth( Mix.pX, Voice.ISP, Parm );
        mSdB = Song.ISP .* Mix.mXdB;
        mSdB = prepareSineSynth( mSdB, Song.ISP, Parm );
        pS = prepareSineSynth( Mix.pX, Song.ISP, Parm );
        Voice.ISP_AS_y = sineSynth( mVdB, pV, Voice.ISP, Parm );
        Voice.ISP_AS_y = resample( Voice.ISP_AS_y,2,1 );
        Voice.ISP_AS_y = scaleAudio( Voice.ISP_AS_y, MinAmp, MaxAmp );
        Song.ISP_AS_y = sineSynth( mSdB, pS, Song.ISP, Parm );
        Song.ISP_AS_y = resample( Song.ISP_AS_y,2,1 );
        Song.ISP_AS_y = scaleAudio( Song.ISP_AS_y, MinAmp, MaxAmp );
        fprintf('Calculate Synthesis need %.2f sec\n', toc);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Step 5 - BSS Evaluation
        tic
        trueVoice = gpuArray(x(:,2));
        trueKaraoke = gpuArray(x(:,1));
        trueMixed = gpuArray(x(:,1)+x(:,2));
        
        estimatedVoice = gpuArray(Voice.ISP_iSTFT_y);
        estimatedKaraoke = gpuArray(Song.ISP_iSTFT_y);
        [SDR, SIR, SAR] = bss_eval_sources([estimatedVoice estimatedKaraoke]' / norm(estimatedVoice + estimatedKaraoke), [trueVoice trueKaraoke]' / norm(trueVoice + trueKaraoke));
        [NSDR, ~, ~] = bss_eval_sources([trueMixed trueMixed]' / norm(trueMixed + trueMixed), [trueVoice trueKaraoke]' / norm(trueVoice + trueKaraoke));
        NSDR = SDR - NSDR;
        
        ISP_iSTFT_BSS(t,(l*6)-5) = gather(NSDR(1));
        ISP_iSTFT_BSS(t,(l*6)-4) = gather(NSDR(2));
        ISP_iSTFT_BSS(t,(l*6)-3) = gather(SIR(1));
        ISP_iSTFT_BSS(t,(l*6)-2) = gather(SIR(2));
        ISP_iSTFT_BSS(t,(l*6)-1) = gather(SAR(1));
        ISP_iSTFT_BSS(t,l*6) = gather(SAR(2));
        
        fprintf('ISP iSTFT NSDR:%.4f, %.4f\n', NSDR(1), NSDR(2));
        fprintf('ISP iSTFT SIR:%.4f, %.4f\n', SIR(1), SIR(2));
        fprintf('ISP iSTFT SAR:%.4f, %.4f\n', SAR(1), SAR(2));
        fprintf('Computing %d BSSEval - (Voice, Song)] - needs %.2f sec\n', t, toc);
        
        estimatedVoice = gpuArray(Voice.ISP_AS_y);
        estimatedKaraoke = gpuArray(Song.ISP_AS_y);
        [SDR, SIR, SAR] = bss_eval_sources([estimatedVoice estimatedKaraoke]' / norm(estimatedVoice + estimatedKaraoke), [trueVoice trueKaraoke]' / norm(trueVoice + trueKaraoke));
        [NSDR, ~, ~] = bss_eval_sources([trueMixed trueMixed]' / norm(trueMixed + trueMixed), [trueVoice trueKaraoke]' / norm(trueVoice + trueKaraoke));
        NSDR = SDR - NSDR;
        
        ISP_AS_BSS(t,(l*6)-5) = gather(NSDR(1));
        ISP_AS_BSS(t,(l*6)-4) = gather(NSDR(2));
        ISP_AS_BSS(t,(l*6)-3) = gather(SIR(1));
        ISP_AS_BSS(t,(l*6)-2) = gather(SIR(2));
        ISP_AS_BSS(t,(l*6)-1) = gather(SAR(1));
        ISP_AS_BSS(t,l*6) = gather(SAR(2));
        
        fprintf('ISP AS NSDR:%.4f, %.4f\n', NSDR(1), NSDR(2));
        fprintf('ISP AS SIR:%.4f, %.4f\n', SIR(1), SIR(2));
        fprintf('ISP AS SAR:%.4f, %.4f\n', SAR(1), SAR(2));
        fprintf('Computing %d BSSEval - (Voice, Song)] - needs %.2f sec\n', t, toc);
        fprintf('=================================================\n');
    end
end