function [ Stat ] = PartialsSizeErr( Partials )

% Stat(1) - Number of Partials
% Stat(2) - Number of Error Partials
% Stat(3) - Mean Partials Size
% Stat(4) - Std Partials Size
% Stat(5) - Max Partials Size
% Stat(6) - Min Partials Size
% Stat(7) - Median Partials Size
% Stat(8) - Mean Err Partials Size
% Stat(9) - Std Err Partials Size
% Stat(10) - Max Err Partials Size
% Stat(11) - Min Err Partials Size
% Stat(12) - Median Err Partials Size

Stat = zeros(1,7);

% EachResult(1) - Number of Voice Peaks
% EachResult(2) - Number of Song Peaks
% EachResult(3) - Partial Size
% EachResult(4) - Error Partial Binary Indicator
Stat(1) = numel(Partials);
EachResult = zeros(Stat(1),4);
for r = 1:Stat(1)
    Partial = Partials{r};
    EachResult(r,1) = Partial.size;
    EachResult(r,2) = numel(find(Partial.type == 1));
    EachResult(r,3) = numel(find(Partial.type == 0));
    
    %% Error Partial
    if EachResult(r,2) ~= 0 && EachResult(r,3) ~= 0
        EachResult(r,4) = 1;
    end
end

ErrIdxs = find(EachResult(:,4) == 1);
Stat(2) = numel(ErrIdxs);
Stat(3) = mean(EachResult(:,1));
Stat(4) = std(EachResult(:,1));
Stat(5) = max(EachResult(:,1));
Stat(6) = min(EachResult(:,1));
Stat(7) = median(EachResult(:,1));

Stat(8) = mean(EachResult(ErrIdxs,1));
Stat(9) = std(EachResult(ErrIdxs,1));
Stat(10) = max(EachResult(ErrIdxs,1));
Stat(11) = min(EachResult(ErrIdxs,1));
Stat(12) = median(EachResult(ErrIdxs,1));

end
