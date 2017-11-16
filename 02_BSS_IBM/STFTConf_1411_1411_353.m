%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This script record the BSS Score of IBM, ISP synthesized with STFT and
%   ISP synthesized with Additive Synthesis, base on the STFT configuration
%   It also export the corresponding audio files.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all; close all; clc

ToolDirStr = '../00_Tools/';
DatabaseDirStr = '../Wavfile/';
AudioOutDirStr = '../Audio/02_BSS_IBM/';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Step 0 - Addpath for SineModel/UtilFunc/BSS_Eval
addpath(genpath(ToolDirStr));
%% Step 0 - Parmaters Setting
% STFT
Parm.M = 1411;                  % Window Size, 63.99ms
Parm.window = hann(Parm.M);     % Window in Vector Form
Parm.N = 1411;                  % Analysis FFT Size, 63.99ms
Parm.H = 353;                   % Hop Size, 16.01ms
Parm.fs = 22050;                % Sampling Rate, 22.05K Hz
Parm.t = 1;                     % Need All Peaks, in term of Mag Level

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Step 0 - Obtain Audio File Name
WavFileDirs = iKalaWavFileNames(DatabaseDirStr);
numMusics = numel(WavFileDirs);
% NSDR, SIR, SAR
IBM_iSTFT_BSS = zeros(numMusics,6);
ISP_iSTFT_BSS = zeros(numMusics,6);
ISP_AS_BSS = zeros(numMusics,6);

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
    % Spectrogram Dimension - Parm.numBins:513 X Parm.numFrames:2584 = 1,325,592
    [~, Voice.mX, ~, ~, ~] = stft(Voice.x, Parm);
    [~, Song.mX, ~, ~, ~] = stft(Song.x, Parm);
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
    Mix.ploc = peakDetection( Mix.mXdB, Parm );
    
    Voice.ISP = Voice.IBM .* Mix.ploc;
    Song.ISP = Song.IBM .* Mix.ploc;
    fprintf('Create IBM needs %.2f sec\n', toc);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Step 3 - Synthesis
    tic
    mV = Voice.IBM .* Mix.mX;
    mS = Song.IBM .* Mix.mX;
    Voice.IBM_iSTFT_y = istft(mV, Mix.pX, Parm ); 
    Voice.IBM_iSTFT_y = resample(Voice.IBM_iSTFT_y,2,1);
    Voice.IBM_iSTFT_y = scaleAudio( Voice.IBM_iSTFT_y, MinAmp, MaxAmp );
    Song.IBM_iSTFT_y = istft(mS, Mix.pX, Parm ); 
    Song.IBM_iSTFT_y = resample(Song.IBM_iSTFT_y,2,1);
    Song.IBM_iSTFT_y = scaleAudio( Song.IBM_iSTFT_y, MinAmp, MaxAmp );
    
    mV = Voice.ISP .* Mix.mX;
    mS = Song.ISP .* Mix.mX;
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
    fprintf('Calculating Synthesis need %.2f sec\n', toc);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Step 4 - Generate Audio
    tic
    if t <= 137
        audiowrite([AudioOutDirStr, 'IBM_iSTFT/1411_1411_353/Voice/',WavFileDirs{t}(end-14:end)], Voice.IBM_iSTFT_y, fs);
        audiowrite([AudioOutDirStr, 'IBM_iSTFT/1411_1411_353/Song/',WavFileDirs{t}(end-14:end)], Song.IBM_iSTFT_y, fs);
        audiowrite([AudioOutDirStr, 'ISP_iSTFT/1411_1411_353/Voice/',WavFileDirs{t}(end-14:end)], Voice.ISP_iSTFT_y, fs);
        audiowrite([AudioOutDirStr, 'ISP_iSTFT/1411_1411_353/Song/',WavFileDirs{t}(end-14:end)], Song.ISP_iSTFT_y, fs);
        audiowrite([AudioOutDirStr, 'ISP_AS/1411_1411_353/Voice/',WavFileDirs{t}(end-14:end)], Voice.ISP_AS_y, fs);
        audiowrite([AudioOutDirStr, 'ISP_AS/1411_1411_353/Song/',WavFileDirs{t}(end-14:end)], Song.ISP_AS_y, fs);
    else
        audiowrite([AudioOutDirStr, 'IBM_iSTFT/1411_1411_353/Voice/',WavFileDirs{t}(end-15:end)], Voice.IBM_iSTFT_y, fs);
        audiowrite([AudioOutDirStr, 'IBM_iSTFT/1411_1411_353/Song/',WavFileDirs{t}(end-15:end)], Song.IBM_iSTFT_y, fs);
        audiowrite([AudioOutDirStr, 'ISP_iSTFT/1411_1411_353/Voice/',WavFileDirs{t}(end-15:end)], Voice.ISP_iSTFT_y, fs);
        audiowrite([AudioOutDirStr, 'ISP_iSTFT/1411_1411_353/Song/',WavFileDirs{t}(end-15:end)], Song.ISP_iSTFT_y, fs);    
        audiowrite([AudioOutDirStr, 'ISP_AS/1411_5466_353/Voice/',WavFileDirs{t}(end-15:end)], Voice.ISP_AS_y, fs);
        audiowrite([AudioOutDirStr, 'ISP_AS/1411_5466_353/Song/',WavFileDirs{t}(end-15:end)], Song.ISP_AS_y, fs);
    end
    fprintf('Generate Audio needs %.2f sec\n', toc);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Step 5 - BSS Evaluation
    tic
    trueVoice = gpuArray(x(:,2));
    trueKaraoke = gpuArray(x(:,1));
    trueMixed = gpuArray(x(:,1)+x(:,2));
    
    estimatedVoice = gpuArray(Voice.IBM_iSTFT_y);
    estimatedKaraoke = gpuArray(Song.IBM_iSTFT_y);
    [SDR, SIR, SAR] = bss_eval_sources([estimatedVoice estimatedKaraoke]' / norm(estimatedVoice + estimatedKaraoke), [trueVoice trueKaraoke]' / norm(trueVoice + trueKaraoke));
    [NSDR, ~, ~] = bss_eval_sources([trueMixed trueMixed]' / norm(trueMixed + trueMixed), [trueVoice trueKaraoke]' / norm(trueVoice + trueKaraoke));
    NSDR = SDR - NSDR;
    
    IBM_iSTFT_BSS(t,1) = gather(NSDR(1));
    IBM_iSTFT_BSS(t,2) = gather(NSDR(2));
    IBM_iSTFT_BSS(t,3) = gather(SIR(1));
    IBM_iSTFT_BSS(t,4) = gather(SIR(2));
    IBM_iSTFT_BSS(t,5) = gather(SAR(1));
    IBM_iSTFT_BSS(t,6) = gather(SAR(2));
    
    fprintf('IBM iSTFT NSDR:%.4f, %.4f\n', NSDR(1), NSDR(2));
    fprintf('IBM iSTFT SIR:%.4f, %.4f\n', SIR(1), SIR(2));
    fprintf('IBM iSTFT SAR:%.4f, %.4f\n', SAR(1), SAR(2));
    fprintf('Computing %d BSSEval - (Voice, Song)] - needs %.2f sec\n', t, toc);
    
    tic
    estimatedVoice = gpuArray(Voice.ISP_iSTFT_y);
    estimatedKaraoke = gpuArray(Song.ISP_iSTFT_y);
    [SDR, SIR, SAR] = bss_eval_sources([estimatedVoice estimatedKaraoke]' / norm(estimatedVoice + estimatedKaraoke), [trueVoice trueKaraoke]' / norm(trueVoice + trueKaraoke));
    [NSDR, ~, ~] = bss_eval_sources([trueMixed trueMixed]' / norm(trueMixed + trueMixed), [trueVoice trueKaraoke]' / norm(trueVoice + trueKaraoke));
    NSDR = SDR - NSDR;
    
    ISP_iSTFT_BSS(t,1) = gather(NSDR(1));
    ISP_iSTFT_BSS(t,2) = gather(NSDR(2));
    ISP_iSTFT_BSS(t,3) = gather(SIR(1));
    ISP_iSTFT_BSS(t,4) = gather(SIR(2));
    ISP_iSTFT_BSS(t,5) = gather(SAR(1));
    ISP_iSTFT_BSS(t,6) = gather(SAR(2));
        
    fprintf('ISP iSTFT NSDR:%.4f, %.4f\n', NSDR(1), NSDR(2));
    fprintf('ISP iSTFT SIR:%.4f, %.4f\n', SIR(1), SIR(2));
    fprintf('ISP iSTFT SAR:%.4f, %.4f\n', SAR(1), SAR(2));
    fprintf('Computing %d BSSEval - (Voice, Song)] - needs %.2f sec\n', t, toc);
    
    tic
    estimatedVoice = gpuArray(Voice.ISP_AS_y);
    estimatedKaraoke = gpuArray(Song.ISP_AS_y);
    [SDR, SIR, SAR] = bss_eval_sources([estimatedVoice estimatedKaraoke]' / norm(estimatedVoice + estimatedKaraoke), [trueVoice trueKaraoke]' / norm(trueVoice + trueKaraoke));
    [NSDR, ~, ~] = bss_eval_sources([trueMixed trueMixed]' / norm(trueMixed + trueMixed), [trueVoice trueKaraoke]' / norm(trueVoice + trueKaraoke));
    NSDR = SDR - NSDR;
    
    ISP_AS_BSS(t,1) = gather(NSDR(1));
    ISP_AS_BSS(t,2) = gather(NSDR(2));
    ISP_AS_BSS(t,3) = gather(SIR(1));
    ISP_AS_BSS(t,4) = gather(SIR(2));
    ISP_AS_BSS(t,5) = gather(SAR(1));
    ISP_AS_BSS(t,6) = gather(SAR(2));
        
    fprintf('ISP AS NSDR:%.4f, %.4f\n', NSDR(1), NSDR(2));
    fprintf('ISP AS SIR:%.4f, %.4f\n', SIR(1), SIR(2));
    fprintf('ISP AS SAR:%.4f, %.4f\n', SAR(1), SAR(2));
    fprintf('Computing %d BSSEval - (Voice, Song)] - needs %.2f sec\n', t, toc);
    fprintf('=================================================\n');
end
