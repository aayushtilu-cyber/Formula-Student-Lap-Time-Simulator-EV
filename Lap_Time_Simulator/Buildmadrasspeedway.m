clc; clear; close all;

%% Read KML file as text
filename = 'Madras_Centerline.kml';  % make sure name matches exactly
txt = fileread(filename);

%% Extract coordinates section
expr = '<coordinates>([\s\S]*?)</coordinates>';
tokens = regexp(txt, expr, 'tokens');

coordString = tokens{1}{1};

%% Split coordinates
coordPairs = strsplit(strtrim(coordString));

N = length(coordPairs);

lat = zeros(N,1);
lon = zeros(N,1);

for i = 1:N
    parts = strsplit(coordPairs{i}, ',');
    lon(i) = str2double(parts{1});
    lat(i) = str2double(parts{2});
end

%% Convert lat/lon to local meters

lat0 = mean(lat);
lon0 = mean(lon);

R = 6371000; % Earth radius in meters

x = R * deg2rad(lon - lon0) .* cos(deg2rad(lat0));
y = R * deg2rad(lat - lat0);

%% Build waypoint matrix
wp = [x y];

% Remove duplicate consecutive points
diff_wp = diff(wp);
dist = sqrt(sum(diff_wp.^2,2));

valid = [true; dist > 1e-6];   % keep first + non-zero distance points
wp = wp(valid,:);

% Close loop safely
if norm(wp(1,:) - wp(end,:)) > 1e-3
    wp = [wp; wp(1,:)];
end

%% Smooth & Resample
t = [0; cumsum(sqrt(sum(diff(wp).^2,2)))];

ppx = spline(t, wp(:,1)');
ppy = spline(t, wp(:,2)');

ds = 1; % 1 meter spacing
s = 0:ds:t(end);

pathX = ppval(ppx,s);
pathY = ppval(ppy,s);

dx = gradient(pathX,ds);
dy = gradient(pathY,ds);

pathYaw = unwrap(atan2(dy,dx));

trackLength = sum(sqrt(diff(pathX).^2 + diff(pathY).^2));

disp(['Track Length = ', num2str(trackLength), ' meters'])

figure
plot(pathX,pathY,'k','LineWidth',2)
axis equal
grid on
title('Madras International Circuit')

%% Curvature Calculation

d2x = gradient(dx, ds);
d2y = gradient(dy, ds);

kappa = (dx .* d2y - dy .* d2x) ./ ...
        ((dx.^2 + dy.^2).^(3/2) + 1e-6);

save('KariTrack.mat','pathX','pathY','pathYaw','kappa','trackLength')
