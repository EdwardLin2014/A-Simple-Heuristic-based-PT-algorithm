function [ norVoiceFeature, norSongFeature, norTrainData, trainLabel ] = NormalizedFeatures( VoiceTrain,SongTrain )

[NumVoice, ~] = size(VoiceTrain);
[NumSong, ~] = size(SongTrain);
NumTrainInstances = NumVoice + NumSong;
trainData = [VoiceTrain;SongTrain];
trainLabel = ones(NumTrainInstances,1);
trainLabel(NumVoice+1:end) = -1;

maxCol = max(trainData); maxColExt = repmat(maxCol, NumTrainInstances, 1);
minCol = min(trainData); minColExt = repmat(minCol, NumTrainInstances, 1);
norTrainData = 2*((trainData-minColExt) ./ (maxColExt-minColExt)) - 1;

norVoiceFeature = norTrainData(1:NumVoice,:);
norSongFeature = norTrainData(NumVoice+1:end,:);

end

