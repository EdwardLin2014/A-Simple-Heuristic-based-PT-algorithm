function Partials = PT_Algo_SMS( mXdB, ploc, vploc, Parm )
%% SMS Sinusoidal Partials Tracking Algorithm
%% Input
%                 mXdB: Power spectrogram
%                 ploc: Peak Location
%                vploc: Voice Peak Location (optional)
%    Parm.freqDevSlope: Slope of the frequency deviation
%   Parm.freqDevOffset: The minimum frequency deviation at 0 Hz
%       Parm.numFrames: Number of frames
%           Parm.mindB: the minimum dB of power spectrogram
%           Parm.maxdB: the maximum dB of power spectrogram
if ~isfield(Parm, 'freqDevSlope'); freqDevSlope = 0.01; else freqDevSlope = Parm.freqDevSlope; end
if ~isfield(Parm, 'freqDevOffset'); freqDevOffset = 20; else freqDevOffset = Parm.freqDevOffset; end
if ~isfield(Parm, 'numFrames'); numFrames = 2584; else numFrames = Parm.numFrames; end
if ~isfield(Parm, 'mindB'); mindB = min(min(mXdB)); else mindB = Parm.mindB; end
if ~isfield(Parm, 'maxdB'); maxdB = max(max(mXdB)); else maxdB = Parm.maxdB; end

pfreq = cell(numFrames,1);
pmag = cell(numFrames,1);
pfreqIdx = cell(numFrames,1);
pmagIdx = cell(numFrames,1);
ptype = cell(numFrames,1);
pnum = zeros(numFrames,1);

for n = 1:numFrames
    idxs = find(ploc(:,n));
    %% Set Priority for the current peak to choose its most suitable partial
    pmag{n} = mXdB(idxs,n);
    [pmag{n}, pkMagOrder] = sort(pmag{n}, 'descend');
    pfreq{n} = FBinToHz(idxs(pkMagOrder),Parm);
    pmagIdx{n} = dBToMagLvl(pmag{n}, mindB, maxdB);
    pfreqIdx{n} = idxs(pkMagOrder);
    ptype{n} = vploc(idxs(pkMagOrder),n);
    pnum(n) = numel(idxs);
end

%% Ouput
Tracks = [];
% 0: Not Selected
% 1: Selected
% -1: Deactive
TracksStatus = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Sinusoidal Tracking Starts
for t = 1:numFrames
    
    CurNumPeaks = pnum(t);
    NotSelectedPeaks = true(1,CurNumPeaks);
    
    %% Continue Active Tracks, if exist
    if any(TracksStatus == 0)
        
        % Active Track
        NumNotAssignTrack = numel(find(TracksStatus == 0));
        PrevPeak = zeros(NumNotAssignTrack,3);
        SelectedTracks = false(1,NumNotAssignTrack);
        p = 1;
        for r = find(TracksStatus == 0)
            PrevPeak(p, 1) = Tracks{r}.freq(end);            % copy latest peaks of Active Track
            PrevPeak(p, 2) = Tracks{r}.mag(end);             % copy latest peaks of Active Track
            PrevPeak(p, 3) = r;                              % For logistic
            p = p + 1;
        end
        
        for c = 1:CurNumPeaks
            %% If all active tracks are assigned, break!
            if NumNotAssignTrack == 0
                break;
            end
            
            %% Find the most suitable tracks
            % Frist, find current peaks within Frequency and Magnitude Range
            DiffFreq = abs(pfreq{t}(c) - PrevPeak(:,1));
            FreqCond = freqDevSlope*pfreq{t}(c) + freqDevOffset;
            
            % Find intersect peaks
            idxs = (DiffFreq < FreqCond);
            idxs(SelectedTracks) = 0;           % Kick out the selected tracks
            idxs = find(idxs);                  % Find the indexs of a logical array
            if numel(idxs)==0                       
                continue;
            end
            % Must connect the current peak to the selected Partials
            % Within the intesect peaks, use the minimum frequency
            [~, idx] = min(DiffFreq(idxs));
            r = PrevPeak(idxs(idx), 3);
            % Link the current peak to the selected track
            Tracks{r}.mag(end+1) = pmag{t}(c);
            Tracks{r}.freq(end+1) = pfreq{t}(c);
            Tracks{r}.magIdx(end+1) = pmagIdx{t}(c);
            Tracks{r}.freqIdx(end+1) = pfreqIdx{t}(c);
            Tracks{r}.size = Tracks{r}.size + 1;
            Tracks{r}.type(end+1) = ptype{t}(c);
            % Maintain the logistic for sinusoidal tracking
            NotSelectedPeaks(c) = 0;
            SelectedTracks(idxs(idx)) = 1;
            TracksStatus(r) = 1;
            NumNotAssignTrack = NumNotAssignTrack - 1;
        end
    end
    
    %% Deactive all non selected active tracks
    for r = find(TracksStatus == 0)
        Tracks{r}.period(2) = t-1;
    end
    TracksStatus(TracksStatus == 0) = -1;
    
    % Music is ended, silent or at onset, deactivate all active track
    if (t == numFrames || CurNumPeaks == 0) && ~isempty(TracksStatus == 1)
        for r = find(TracksStatus == 1)
            if t == numFrames
                Tracks{r}.period(2) = t;
            else
                Tracks{r}.period(2) = t-1;
            end
        end
        TracksStatus(TracksStatus == 1) = -1;
    end
    
    % Reinitialised
    TracksStatus(TracksStatus == 1) = 0;
    
    % The remaining peaks prepare to form new tracks
    for p = find(NotSelectedPeaks)
        NewTracks.period(1) = t;
        if t == numFrames
            NewTracks.period(2) = t;
        end
        NewTracks.mag = pmag{t}(p);
        NewTracks.freq = pfreq{t}(p);
        NewTracks.magIdx = pmagIdx{t}(p);
        NewTracks.freqIdx = pfreqIdx{t}(p);
        NewTracks.size = 1;
        NewTracks.type = ptype{t}(p);
        
        Tracks{end+1,1} = NewTracks;
        TracksStatus(end+1) = 0;
    end
end

% delete track which is short that the minimum partial length
numTracks = numel(Tracks);
delTrackIdxs = [];
for idx = 1:numTracks
    Track = Tracks{idx};
    if Track.size < Parm.minPartialLength
        delTrackIdxs = [delTrackIdxs, idx];
    end
end
Tracks(delTrackIdxs) = [];
Partials = Tracks;

end

