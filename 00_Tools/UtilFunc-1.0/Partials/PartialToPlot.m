function [ PlotPartials ] = PartialToPlot( Partials, TimeDim, MagLvl )

NumPartials = numel(Partials);
PlotPartials = zeros(NumPartials, TimeDim);
PlotPartials(:,:) = nan;

for j = 1:NumPartials
    if max(Partials{j}.magIdx) >= MagLvl
        PlotPartials(j, Partials{j}.period(1):Partials{j}.period(2)) = Partials{j}.freq;
    end
end


end

