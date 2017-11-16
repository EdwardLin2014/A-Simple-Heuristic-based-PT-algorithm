function [ VoicePartials, SongPartials ] = ClassifyPartials( Partials )

VoiceIdx = [];
SongIdx = [];

numPartials = numel(Partials);
for idx = 1:numPartials
    Partial = Partials{idx};
    numVoice = numel(find(Partial.type == 1));
    numSong = numel(find(Partial.type == 0));
    
    if numVoice > numSong
        VoiceIdx = [VoiceIdx; idx];
    else
        SongIdx = [SongIdx; idx];
    end    
end

VoicePartials = Partials(VoiceIdx);
SongPartials = Partials(SongIdx);
