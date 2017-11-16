%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This script find the best parameters of FM based on NSDR
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all; close all; clc

ToolDirStr = '../../00_Tools/';
DatabaseDirStr = '../../Wavfile/';

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
Parm.minPartialLength = 4;      % Min Partial length, 4 peaks, 46.44ms

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
WavFileDirs = iKalaWavFileNames(DatabaseDirStr);
numMusics = numel(WavFileDirs);
PT_BSS = zeros(numMusics,6*100);
PT_Sine_BSS = zeros(numMusics,6*100);

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
    %% Step 2 - Create Ideal Spectral Peaks
    tic
    Voice.IBM = Voice.mX > Song.mX;
    Song.IBM = Voice.mX <= Song.mX;
    Mix.ploc = peakDetection( Mix.mXdB, Parm );
    Voice.ISP = Voice.IBM .* Mix.ploc;
    Song.ISP = Song.IBM .* Mix.ploc;
    fprintf('Create Ideal Spectral Peaks needs %.2f sec\n', toc);
    
    a = 1;
    for MagCond = 1:10               % 1-10 dB
        b = 1;
        Parm.MagCond = MagCond;
        for freqDevOffset = 5:5:50        % The minimum frequency deviation at 0 Hz
            Parm.freqDevOffset = freqDevOffset;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %% Step 3 - Create Sinusoidal Partials
            tic
            Partials = PT_Algo_FM_C( Mix.mXdB, Mix.ploc, Voice.ISP, Parm );
            fprintf('Create Sinusoidal Partials needs %.2f sec\n', toc);
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %% Step 4 - Classify Sinusoidal Partials
            tic
            [ Voice.Partials, Song.Partials ] = ClassifyPartials( Partials );
            fprintf('Classify Sinusoidal Partials need %.2f sec\n', toc);
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %% Step 5 - iSTFT/Additive Synthesis
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
            fprintf('Computing iSTFT/Additive Synthesis need %.2f sec\n', toc);
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %% Step 6 - BSS Evaluation
            tic
            trueVoice = gpuArray(x(:,2));
            trueKaraoke = gpuArray(x(:,1));
            trueMixed = gpuArray(x(:,1)+x(:,2));
            
            estimatedVoice = gpuArray(Voice.ISP_iSTFT_y);
            estimatedKaraoke = gpuArray(Song.ISP_iSTFT_y);
            [SDR, SIR, SAR] = bss_eval_sources([estimatedVoice estimatedKaraoke]' / norm(estimatedVoice + estimatedKaraoke), [trueVoice trueKaraoke]' / norm(trueVoice + trueKaraoke));
            [NSDR, ~, ~] = bss_eval_sources([trueMixed trueMixed]' / norm(trueMixed + trueMixed), [trueVoice trueKaraoke]' / norm(trueVoice + trueKaraoke));
            NSDR = SDR - NSDR;
            
            PT_BSS(t,(a-1)*60+(b*6)-5) = gather(NSDR(1));
            PT_BSS(t,(a-1)*60+(b*6)-4) = gather(NSDR(2));
            PT_BSS(t,(a-1)*60+(b*6)-3) = gather(SIR(1));
            PT_BSS(t,(a-1)*60+(b*6)-2) = gather(SIR(2));
            PT_BSS(t,(a-1)*60+(b*6)-1) = gather(SAR(1));
            PT_BSS(t,(a-1)*60+b*6) = gather(SAR(2));
            
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
            
            PT_Sine_BSS(t,(a-1)*60+(b*6)-5) = gather(NSDR(1));
            PT_Sine_BSS(t,(a-1)*60+(b*6)-4) = gather(NSDR(2));
            PT_Sine_BSS(t,(a-1)*60+(b*6)-3) = gather(SIR(1));
            PT_Sine_BSS(t,(a-1)*60+(b*6)-2) = gather(SIR(2));
            PT_Sine_BSS(t,(a-1)*60+(b*6)-1) = gather(SAR(1));
            PT_Sine_BSS(t,(a-1)*60+b*6) = gather(SAR(2));
            
            fprintf('ISP AS NSDR:%.4f, %.4f\n', NSDR(1), NSDR(2));
            fprintf('ISP AS SIR:%.4f, %.4f\n', SIR(1), SIR(2));
            fprintf('ISP AS SAR:%.4f, %.4f\n', SAR(1), SAR(2));
            fprintf('Computing %d BSSEval - (Voice, Song)] - needs %.2f sec\n', t, toc);
            fprintf('=================================================\n');
            
            b = b + 1;
        end
        a = a + 1;
    end
end

