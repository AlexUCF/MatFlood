function wlgrid = spat_var_wl(lon,lat,z,tg,L)
% spat_var_wl_5 calculates spatially varying flood water level based on a
% given set of water levels located in the study area.
% The difference between v5 and v4 it's that the background in v5 is the
% mean value instead the min
% 
% Inputs:
% lon:      longitude grid (columns)
% lat:      latitude grid (rows)
% z:        elevation (bathy-topography)
%           lon, lat, and z may have the same size [M,N]
% tg:       given set of flood water levels. Must contain: [lon,lat,wl];
% L:        correlation length. Defined by user, L = 9 otherwise
%
% ---------
% Outputs:
% wlgrid:   two dimensinal spatially varying flood water level of [M,N]


%% Reduce spatial resolution

sires= round(size(z)/10);

% in case z is already very small (500x500)
if size(z,1)<= 500
    sires(1)= size(z,1);
end

if size(z,2)<= 500
    sires(2) = size(z,2);
end

lat2 = imresize(lat,sires);
lon2 = imresize(lon,sires);
z2   = imresize(z, sires);

land = [lon2(:),lat2(:),z2(:)];

%% Optimal interpolation parameters

% Correlation length
if exist('L','var')== 0 
    L = 9;
end
    
g  = 0.01;              % gamma, obs error = (E,inst+E,rep)/Var;
Rt = 6371;              % earth radio

%% Input data

tg(isnan(tg(:,3)),:)= [];

Vback   = mean(tg(:,end));              % background
Vo      = [tg(:,1:2) tg(:,end)-Vback];  % anomalies and coordinates
Va      = land(:,1:2);                  % topography grid

%% Covariance matrix
% Calculate distances between topography coordinates and tide gauge/ model observations

r_lat = (2*pi*Rt)/360;
DE    = zeros(size(Va,1),size(Vo,1));

for i = 1: size(Va,1)
        
    for j = 1: size(Vo,1)
        
       r_lon   = 2*pi*Rt*cosd((Va(i,2)+Vo(j,2))/2)/360;
       DE(i,j) = sqrt(((Va(i,1) - Vo(j,1))*r_lon)^2+((Va(i,2) - Vo(j,2))*r_lat)^2);
       
    end    
end

% Weitgh matrix (topography vs observations)
WD = exp((-DE.^2)./(2*L^2));
 
%% Covariance matrix
% Calculate distances among observations

TE = zeros(size(Vo,1),size(Vo,1));

for i=1:size(Vo,1)
    for j=1:size(Vo,1)
        
        r_lon   = 2*pi*Rt*cosd((Vo(i,2)+Vo(j,2))/2)/360;
        TE(i,j) = sqrt((( Vo(i,1) - Vo(j,1))*r_lon)^2+((Vo(i,2) - Vo(j,2))*r_lat)^2);
        
    end
end

%  Weight matrix between observations
WT = exp((-TE.^2)./(2*L^2));

%% Gamma = diagonal matrix (error among observations/ model points)
gamma      = g(1)*ones(size(WT,1),1);
gamma      = diag(gamma);
TTT        = WT + gamma;

%% normalizing the matrix
P         = WD*inv(TTT); 
P(P < 0)  = 0;           % remove negative values
sumapeso  = sum(P,2);
sumapeso  = max(sumapeso,1);
Pnorm     = P./repmat(sumapeso,1,size(P,2));

% topography vector
Vares   = [Va(:,1) Va(:,2) Pnorm*Vo(:,3)];
Vinterp = [Vares(:,1:2) Vares(:,end)+Vback];

% getting it back to the original resolution
Vintgridlow = reshape(Vinterp(:,end),size(z2));
wlgrid      = griddata(lon2,lat2,Vintgridlow,lon,lat);

%% Correction to keep the maximum value
d      = max(tg(:,3)) - max(max(wlgrid));
wlgrid = wlgrid+d;





