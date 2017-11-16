function [ Features ] = PartialsFeatures( Partials, PParm )
%%
%   Convert Partials to its normalized feature vector

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

[ Size,Freq,ZFreq,Mag,ZMag ] = PartialsSizeFreqMag( Partials );
[Vibrato, Tremolo ] = PartialsVibTre( Partials, PParm );

Features = [Size,Freq,ZFreq,Mag,ZMag,Vibrato,Tremolo];

end

