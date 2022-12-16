function [MinDists,Pos] = calc_distance_utm(land,coastline)

MinDists  = nan(size(land,1),1);
Pos       = MinDists;

for j = 1: size(land,1)
    
    [mindist,pos] = min(abs(((coastline(:,1) - repmat(land(j,1),size(coastline,1),1)))+...
        ((coastline(:,2) - land(j,2)))));
    
    MinDists(j,1)= mindist; 
    Pos(j,1)     = pos;
    
end

