function [ Scaledsong ] = scaleAudio( song, MinAmp, MaxAmp )

UpperSong = song;
UpperSong(UpperSong<=0) = 0;
UpperSong(UpperSong>=0) = ScaleToRange( 0, MaxAmp, UpperSong(UpperSong>=0) );

LowerSong = song;
LowerSong(LowerSong>=0) = 0;
LowerSong(LowerSong<=0) = ScaleToRange( MinAmp, 0, LowerSong(LowerSong<=0) );

Scaledsong = UpperSong + LowerSong;

end

