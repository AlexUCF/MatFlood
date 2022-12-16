%%% Apply reduction factor

function [FloodDepthVecRF,FloodDepthRF,prevcalc,is]= red_fac(lon,lat,z,wb,FloodDepth,xy,zred,prevcalcin)
% Reduces the flooding extension and flooding depth according to zred./xy
%
% Inputs:
% lon:          longitude grid (columns)
% lat:          latitude grid (rows)
% z:            elevation (bathy-topography) lon, lat, and z may have the 
%               same size [M,N]
% wb:           one point (lon, lat) indicating some place in the main 
%               water body (sea or river)
% FloodDepth:   grid of flood depth [M,N] with data only on the
%               flooded grids
% xy:           horizontal length (in meters) used to caculate the 
%               reduction factor (example below)
% zred:         flood depth reduced every xy (in meters) (example below)
% prevcalcin:   coastline and distance to the coastline from previous runs,
%               used to speed up test runs
% is:                  positions in the matrix where inundation takes place
%                      (i.e., positions of FloodDepthVec in [M,N])
%
% example:
% every 1000 m in horizontal, it reduces 1 m of flood depth
% xy   = 1000;
% zred = 1;
% -----------
%
% Outputs:
% FloodDepthVecRF:       coordinates [lon, lat] of flooded grid points and
%                        flood depth (meters)
% FloodDepthRF:          grid of flood depth [M,N] for new flooded areas only
% prevcalc:              coastline and distance to the coastline, used to
%                        speed up test runs


FloodDepth = FloodDepth.*-1;

if exist('prevcalcin','var')== 0 % to calculate coastline and distmat_int

%% 1. reduce spatial resolution

% size of the reduced resolution data
[r,c]= size(z);
res  = 50;
rres = round(r/res);
cres = round(c/res);

lat2 = imresize(lat,[rres,cres]);
lon2 = imresize(lon,[rres,cres]);
z2   = imresize(z, [rres,cres]);

% %% 2. find coastline (using the initial spatial resolution)
% coastline= find_coastline_v4(lon2, lat2, z2, wb);

%% 2. find coastline (using the initial spatial resolution)
coastline= find_coastline(lon, lat, z, wb);

%% 3. find distances from every point to the coast using DEM
land= [lon2(:),lat2(:),z2(:)];

% calculate distances
MinDists= calc_distance(land(:,1:2),coastline(:,1:2));

% reshape into a matrix
distmat = reshape(MinDists,size(z2));

%% 4. transfer distances to the original resolution
distmat_int = griddata(lon2,lat2,distmat,lon,lat);

else % if coastline and distmat_int are inputs from a previous calculation
    coastline   = prevcalcin.coastline;
    distmat_int = prevcalcin.distmat_int;
end
    
%% 5. apllying reduction factor
wl_depth_red =  FloodDepth + (zred.*distmat_int./xy);

% remove those areas that are not inundated anymore
wl_depth_red(wl_depth_red> 0) = nan;

%% 6. correction: apply tool again to remove those polygons not connected to the sea
% sea level (sl) always has to be 0 because I don't want to change the flooded areas
sl0= 0; 

z_flood= z;
z_flood(~isnan(wl_depth_red)) = wl_depth_red(~isnan(wl_depth_red));  % new flooded area

% run HC Static Flooding method to remove flooded areas not connected to the main water body
[~, ~, FloodDepthAndSea] = StaticFlooding(lon, lat, z_flood, sl0, wb); 

% remove main water body and land
FloodDepthRF          = FloodDepthAndSea;
FloodDepthRF(z<= 0)   = nan;

% vector format
FloodDepthVecRF                                   = [lon(:) lat(:) FloodDepthRF(:)];
is                                                = find(~isnan(FloodDepthVecRF(:,3)));
FloodDepthVecRF(isnan(FloodDepthVecRF(:,3)),:)    = [];

%% Coastline and distances to the coast                        
prevcalc.distmat_int= distmat_int;   % matrix of distances values (in 
                                     % meters) between each point and 
                                     % the coastline
                                    
prevcalc.coastline= coastline;       % matrix of [M,N], being M the number 
                                     % of points defining the coastline and 
                                     % N= 3. N(:,1) contains longitude of
                                     % the coastline; N(:,2) the latitude; 
                                     % N(:,3) the elevation.

%% Sign criteria
FloodDepthVecRF(:,3)   = FloodDepthVecRF(:,3).*-1;
FloodDepthRF           = FloodDepthRF*-1;















