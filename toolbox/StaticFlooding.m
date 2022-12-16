
function [FloodDepthVec, FloodDepth, FloodDepthAndSea, is] =...
    StaticFlooding(lon, lat, z, wl, wb)

% Flooding method: bathtub approach taking into account hydrological
% connections
% --------
% Inputs:
% lon: longitude grid (columns)
% lat: latitude grid (rows)
% z:   elevation (bathy-topography)
%      lon, lat, and z may have the same size [M,N]
% wl:  flood water level used to inundate (matrix format)
% wb:  one point (lon, lat) indicating some place in the main water body 
%      (sea or river)
% --------
% Outputs:
% FloodDepthVec:       coordinates [lon, lat] of flooded grid points and
%                      flood depth (meters)
% FloodDepth:          grid of flood depth [M,N] with data only on the
%                      flooded grids
% FloodDepthAndSea:    flood depth [M,N] including the main water body
% is:                  positions in the matrix where inundation takes place
%                      (i.e., positions of FloodDepthVec in [M,N])

dem_xyz= [lon(:), lat(:), z(:)];

% the topography is reduced by the inundating water level 
zF= z - wl;

% Converting it into a binary black and white image of 1 and 0
zBW             = zF;
zBW(zBW> 0)     = nan;   % land
zBW(zBW<= 0)    = ones;  % water
zBW(isnan(zBW)) = zeros; % land

%% Polygons and holes
Lc = bwboundaries_SFM(zBW);

%% Find the polygon with the sea boundary

% main water body
[~,sea_bound]= calc_distance(wb,dem_xyz);

Lwb1 = Lc{1}(sea_bound);
Lwb2 = Lc{2}(sea_bound);

% polygons
Lp = zeros(size(z));
Lp(Lc{1}== Lwb1)= ones;

% holes
holes = zeros(size(z));
holes(Lc{2}== Lwb2)= 1;

L = Lp + holes;

%% Inundating the main water body + connected areas

fpos                   = find(L== 2);
FloodDepthAndSea       = nan(size(z));
FloodDepthAndSea(fpos) = zF(fpos);

%% Only new land indundated under wl

% grid format
FloodDepth          = nan(size(z));
FloodDepth(fpos)    = FloodDepthAndSea(fpos); % depth of flooded areas
FloodDepth(z<=0)    = nan;                    % remove the main water body from the matrix

% save positions of flooded areas
is = 1:length(z(:));
is = reshape(is,size(z));
is(isnan(FloodDepth)) = [];
is = is(:);

% vector format
FloodDepthVec      = [dem_xyz(:,1:2) FloodDepth(:)];
FloodDepthVec(isnan(FloodDepthVec(:,3)),:) = [];

% sign criteria: positive values of flood depth
FloodDepthVec(:,3)      = FloodDepthVec(:,3)*-1;
FloodDepth              = FloodDepth.*-1;
FloodDepthAndSea(is)    = FloodDepthAndSea(is)*-1;






