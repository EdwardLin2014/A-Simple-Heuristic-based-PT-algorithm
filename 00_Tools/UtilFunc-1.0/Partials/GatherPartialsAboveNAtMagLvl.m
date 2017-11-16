function [ PartialsAboveNAtMagLvl ] = GatherPartialsAboveNAtMagLvl( Partials, MagLvl )

NumOfPartials = numel(Partials);
NumOfPartialsAtMagLvl = 0;

for i=1:NumOfPartials
    Partial = Partials{i};
    if max(Partial.magIdx) >= MagLvl
        NumOfPartialsAtMagLvl = NumOfPartialsAtMagLvl + 1;
    end
end

PartialsAboveNAtMagLvl = cell(NumOfPartialsAtMagLvl,1);
j = 1;
for i=1:NumOfPartials
    Partial = Partials{i};
    if max(Partial.magIdx) >= MagLvl
        PartialsAboveNAtMagLvl{j} = Partial;
        j = j + 1;
    end
end

end

