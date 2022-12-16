function [MinDists,Pos]= calc_distance(land,coastline)
% Calculate distances between longitude,latitude
% land:   vector [lon,lat]
% coastline:   vector [lon,lat]
% ----------
% outputs:
% MinDist:  minimum distance between two lon,lat point in meters
% Pos:      Position where the minimum distance between two lon,lat points
%           was found

Rt        = 6371;              % earth radius (km)
r_lat     = (2*pi*Rt)/360;
MinDists  = nan(size(land,1),1);
Pos       = MinDists;

for j = 1: size(land,1)
    
    r_lon         = 2.*pi.*Rt.*cosd((coastline(:,2)+...
        repmat(land(j,2),size(coastline,1),1))./2)./360;
    
    [mindist,pos] = min(sqrt(((coastline(:,1) - repmat(land(j,1),size(coastline,1),1)).*r_lon).^2+...
        ((coastline(:,2) - land(j,2)).*r_lat).^2));
    
    MinDists(j,1)= mindist*1000; % from km to meters
    Pos(j,1)     = pos;
    
end










