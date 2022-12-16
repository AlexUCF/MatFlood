function [coastline,fBW]= find_coastline_utm(lon,lat,z,wb)

% output:
%-------
% coastline:        matrix of [M,N], being M the number of points defining
%                   the coastline and N= 3. N(:,1) contains longitude of
%                   the coastline; N(:,2) the latitude; N(:,3) the
%                   elevation.
% fBW:              positions of the coastline over the z matrix

% input:
%------
% lon:              longitude (matrix of size(z))
% lat:              latitude (matrix of size(z))
% z:                topo-bathymetry elevation in grid format (original
%                   elevation, not flooded)
% wb:               point (lon,lat) indicating  point on the sea

%% 1. Identify sea body under present day conditions

% black and white bathymetry
zBW= z;
zBW(z>0)= zeros;
zBW(z<=0)= ones;

%% Polygons and holes
Lc = bwboundaries_SFM(zBW);

%% Find the polygon with the sea boundary

% main water body
dem_xyz= [lon(:), lat(:), z(:)];
[~,sea_bound]= calc_distance_utm(wb,dem_xyz);

Lwb1 = Lc{1}(sea_bound);
Lwb2 = Lc{2}(sea_bound);

% polygons
sea = zeros(size(z));
sea(Lc{1}== Lwb1)= ones;

% holes
holes = ones(size(z));
holes(Lc{2}== Lwb2)= 0;

sea(holes== 1)= 0;

%% 2. Define coastline

% find edge
BW  = edge(sea);
fBW = find(BW== 1);

coastline = [lon(:) lat(:) z(:)];
coastline = coastline(fBW,:);

% [fBW(:,1), fBW(:,2)] = ind2sub(size(z),fBW); 

% figure; pcolor(lon,lat,z); shading flat; hold all
% plot(coastline(:,1),coastline(:,2),'.k')

