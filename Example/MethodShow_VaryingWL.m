%%% Show bathtub MatFlood using spatially varying water level %%%

clear; close all; clc

% change path to where the script is
cd('C:\Users\al063242\OneDrive - University of Central Florida\Bathtub Matlab\Example')

% add the toolbox of the model 
addpath(genpath('C:\Users\al063242\OneDrive - University of Central Florida\Bathtub Matlab\toolbox'))

%% input parameters

cd('Input Data')

% DEM
load('DEM.mat')

[rows,columns]= size(elev);

% Three tide gauges (no real)
tg = [-71.0285 42.3317 1;
    -71.0233 42.3470 1.5;
    -71.0342 42.3128 1.7];

% point to indicate water
wb= [-71.03 42.325];

% colormaps (for plotting)
terrain     = load('TerrainColorMap','mycmap');
floodcolors = load('FloodColorMap','mycmap');

%% Plot topography

figure; pcolor(lon,lat,elev); shading flat; colorbar
hold all; 

h1 = plot(wb(1),wb(2),'.m','MarkerSize',20);
h2 = plot(tg(:,1),tg(:,2),'^b','MarkerSize',5,'LineWidth',2);

ax = gca;
colormap(ax,terrain.mycmap)
caxis([0 10])

dz = 0:1:30;
[~, h11]= contour(lon,lat,elev,dz,'color','k','LineWidth',.1,'showtext','off');

title('Elevation data (m), Boston city')
legend([h1,h2],'Point to indicate water','Tide gauges','Location','Best')

%% Get spatially varying flood water level
tic
wlgrid = spat_var_wl(lon,lat,elev,tg);
toc

%% Plot

% get coastline (for plotting purposes only)
[coastline,bW] = find_coastline(lon, lat, elev, wb);

figure; subplot(1,2,1); hold all;
pcolor(lon,lat,wlgrid); shading flat; colorbar

plot(coastline(:,1),coastline(:,2),'.k')

ax = gca;
colormap(ax,floodcolors.mycmap)

title('Spatially varying flood water level (m)')

subplot(1,2,2);
scatter(lon(bW),lat(bW),20,wlgrid(bW))

ax = gca;
colormap(ax,floodcolors.mycmap)

colorbar
title('Flood water level (m) along the coast')

%% Run Flood Static Method

tic
[FloodDepthVec, FloodDepth, FloodDepthAndSea] = ...
    StaticFlooding(lon,lat,elev, wlgrid, wb); 
toc


%% Plot results

% Over satellite
limits = [min(FloodDepthVec(:,1)), min(FloodDepthVec(:,2)); max(FloodDepthVec(:,1)), max(FloodDepthVec(:,2))];

figure;
geolimits([limits(1,2) limits(2,2)],[limits(1,1) limits(2,1)])
geobasemap satellite
hold all
geoscatter(FloodDepthVec(:,2),FloodDepthVec(:,1),3,FloodDepthVec(:,3),...
    'o','filled','MarkerEdgeColor','none','LineWidth',0.01);
colorbar
title('Flood depth  (m)')

ax = gca;
colormap(ax,floodcolors.mycmap)

% Pcolor Depth
figure; 
pcolor(FloodDepth); shading flat;
colorbar
title('Flood depth  (m)')

ax = gca;
colormap(ax,floodcolors.mycmap)






