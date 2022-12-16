%%% Show MatFlood tool %%%

clear; close all; clc

% change path to where the script is
cd('MatFlood\Example')

% add the toolbox of the model 
addpath(genpath('MatFlood\toolbox'))

%% Input parameters

cd('Input Data')

% Load digital elevation data (DEM): coordinates (lon,lat) and elevation in
% meters
load('DEM.mat')

[rows,columns]= size(elev);

% Flood water level (spatially uniform, fwl)
sl= 2;

% point to indicate water (lp)
wb= [-71.03 42.325];

% colormaps (for plotting)
terrain     = load('TerrainColorMap','mycmap');
floodcolors = load('FloodColorMap','mycmap');


%% Plot input data

figure; 
pcolor(lon,lat,elev); shading flat; colorbar

hold all; 
h1 = plot(wb(1),wb(2),'.m','MarkerSize',20);

ax = gca;
colormap(ax,terrain.mycmap)
caxis([0 10])

dz = 0:1:30;
[~, h11]= contour(lon,lat,elev,dz,'color','k','LineWidth',.1,'showtext','off');

title('Elevation data (m), Boston city')
legend(h1,'Point to indicate the position of the main water body (sea)')

%% Run Static Method
tic
[FloodDepthVec, FloodDepth, FloodDepthAndSea] = ...
    StaticFlooding(lon,lat,elev, sl, wb); 
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
title('Flood depth (m)')

ax = gca;
colormap(ax,floodcolors.mycmap)

% Pcolor Depth
figure; 
pcolor(lon,lat,FloodDepth); shading flat;

xlabel('Lon')
ylabel('Lat')
colorbar
title('Flood depth (m)')

ax = gca;
colormap(ax,floodcolors.mycmap)

%% Apply reduction factor
% it reduces 1 m of flood depth every 1000 m in the horizontal
xy   = 1000;
zred = 1;

tic
[FloodDepthVecRF, FloodDepthRF,prevcalc]= red_fac(lon,lat,elev,...
    wb,FloodDepth,xy,zred);
toc

% Plot
figure;
geolimits([limits(1,2) limits(2,2)],[limits(1,1) limits(2,1)])
geobasemap satellite
hold all
geoscatter(FloodDepthVecRF(:,2),FloodDepthVecRF(:,1),3,FloodDepthVecRF(:,3),...
    'o','filled','MarkerEdgeColor','none','LineWidth',0.01);
colorbar
title('Flood depth (m) after reduction factor ')

ax = gca;
colormap(ax,floodcolors.mycmap)

%% Testing different reduction factors. The code runs faster since we use the output from the previous run (prevcalc)

xy = 1000;
Zs = [.5 1.5 2];

for i = 1: length(Zs)
    
    tic
    [FloodDepthVecRFi, FloodDepthRFi]= red_fac(lon,lat,elev,...
        wb,FloodDepth,xy,Zs(i),prevcalc); % Note, only two outputs are needed here
    toc
    
    % Plot
    figure;
    geolimits([limits(1,2) limits(2,2)],[limits(1,1) limits(2,1)])
    geobasemap satellite
    hold all
    geoscatter(FloodDepthVecRFi(:,2),FloodDepthVecRFi(:,1),3,FloodDepthVecRFi(:,3),...
        'o','filled','MarkerEdgeColor','none','LineWidth',0.01);
    colorbar
    title(['Reduction factor ' num2str(i)])

    ax = gca;
    colormap(ax,floodcolors.mycmap)

end


