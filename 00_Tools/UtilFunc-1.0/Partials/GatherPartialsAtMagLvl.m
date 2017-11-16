function [ PartialsAtMagLvl ] = GatherPartialsAtMagLvl( Partials, MagLvl )

NumOfPartials = numel(Partials);
NumOfPartialsAtMagLvl = 0;

for i=1:NumOfPartials
    Partial = Partials{i};
    if max(Partial.magIdx) == MagLvl
        NumOfPartialsAtMagLvl = NumOfPartialsAtMagLvl + 1;
    end
end

PartialsAtMagLvl = cell(NumOfPartialsAtMagLvl,1);
j = 1;
for i=1:NumOfPartials
    Partial = Partials{i};
    if max(Partial.magIdx) == MagLvl
        PartialsAtMagLvl{j} = Partial;
        j = j + 1;
    end
end

end

