clc
clear
close all

%% ==========================================================
% LOAD TRACK
%% ==========================================================

load KariTrack.mat

pathX = pathX(:);
pathY = pathY(:);
pathYaw = pathYaw(:);

%% ==========================================================
% CURVATURE PROCESSING
%% ==========================================================

kappa = abs(kappa(:));

% Store raw curvature
kappa_raw = kappa;

% Smooth curvature
kappa = smoothdata(kappa,'sgolay',31);

% Remove tiny numerical noise
kappa(kappa < 1e-4) = 0;

%% ==========================================================
% DISTANCE VECTOR
%% ==========================================================

ds = sqrt(diff(pathX).^2 + diff(pathY).^2);

s = [0; cumsum(ds)];

N = length(s);

%% ==========================================================
% GGV DATA
% Replace with latest values if updated
%% ==========================================================

SpeedTable = [5 10 15 20 25 30];

AxAccelTable = [ ...
    0.345 ...
    0.345 ...
    0.336 ...
    0.335 ...
    0.335 ...
    0.294 ] * 9.81;

AxBrakeTable = [ ...
    0.570 ...
    0.571 ...
    0.569 ...
    0.579 ...
    0.568 ...
    0.568 ]*9.81;

AyTable = [ ...
    0.991 ...
    0.999 ...
    0.999 ...
    0.993 ...
    0.995 ...
    0.994 ]*9.81;

%% ==========================================================
% CORNER SPEED LIMIT
%
% V = sqrt(Ay/kappa)
%
% Iterative because Ay depends on speed
%% ==========================================================

Vcurve = 100*ones(N,1);

for iter = 1:20

    AyAvail = interp1( ...
        SpeedTable,...
        AyTable,...
        Vcurve,...
        'linear',...
        'extrap');

    Vnew = sqrt( ...
        AyAvail ./ ...
        max(kappa,1e-4));

    Vcurve = min(Vcurve,Vnew);

end

%% ==========================================================
% OPTIONAL SPEED CAP
%% ==========================================================

VehicleTopSpeed = 100;

Vcurve(Vcurve > VehicleTopSpeed) = VehicleTopSpeed;


%% ==========================================================
% FORWARD ACCELERATION PASS
%% ==========================================================

Vfwd = Vcurve;

Vfwd(1) = 0;

for i = 1:N-1

    AxAvail = interp1( ...
        SpeedTable,...
        AxAccelTable,...
        Vfwd(i),...
        'linear',...
        'extrap');

    Vpossible = sqrt( ...
        Vfwd(i)^2 + ...
        2*AxAvail*ds(i));

    Vfwd(i+1) = min( ...
        Vpossible,...
        Vcurve(i+1));

end

%% ==========================================================
% BACKWARD BRAKING PASS
%% ==========================================================

Vref = Vfwd;

for i = N:-1:2

    AxBrakeAvail = interp1( ...
        SpeedTable,...
        AxBrakeTable,...
        Vref(i),...
        'linear',...
        'extrap');

    Vpossible = sqrt( ...
        Vref(i)^2 + ...
        2*AxBrakeAvail*ds(i-1));

    Vref(i-1) = min( ...
        Vref(i-1),...
        Vpossible);

end

%% ==========================================================
% SMOOTH PROFILE
%% ==========================================================

Vref = smoothdata( ...
    Vref,...
    'movmean',...
    15);

%% ==========================================================
% LAP TIME ESTIMATE
%% ==========================================================

LapTime = sum( ds ./ max(Vref(1:end-1),0.1) );

fprintf('\n')
fprintf('=================================\n')
fprintf('Estimated Lap Time = %.2f sec\n',LapTime)
fprintf('Max Speed          = %.2f m/s\n',max(Vref))
fprintf('Min Speed          = %.2f m/s\n',min(Vref))
fprintf('=================================\n')

%% ==========================================================
% PLOTS
%% ==========================================================

figure

subplot(3,1,1)

plot(pathX,pathY,'k','LineWidth',1.5)

axis equal
grid on

xlabel('X [m]')
ylabel('Y [m]')

title('Track')

subplot(3,1,2)

plot(s,Vcurve,'r--','LineWidth',1)

hold on

plot(s,Vref,'b','LineWidth',1.5)

grid on

xlabel('Distance [m]')
ylabel('Speed [m/s]')

legend('Corner Limit','Final Vref')

title('Reference Speed Profile')

subplot(3,1,3)

plot(s,kappa_raw,'r:')
hold on
plot(s,kappa,'b','LineWidth',1.5)

grid on

xlabel('Distance [m]')
ylabel('Curvature [1/m]')

legend('Raw','Smoothed')

title('Track Curvature')

%% ==========================================================
% SAVE FOR SIMULINK
%% ==========================================================

v_ref = Vref;

save('KariTrack_GGV.mat',...
     'pathX',...
     'pathY',...
     'pathYaw',...
     'kappa',...
     'v_ref')

fprintf('\n')
fprintf('Saved KariTrack_GGV.mat\n')
