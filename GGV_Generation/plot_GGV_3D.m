clc
clear
close all

%% Load Data

load('GGV_Raw.mat')

Speed = GGV_Table.Speed;
Ax    = GGV_Table.Ax_G;
Ay    = GGV_Table.Ay_G;

%% Remove NaNs

idx = ~(isnan(Speed) | isnan(Ax) | isnan(Ay));

Speed = Speed(idx);
Ax    = Ax(idx);
Ay    = Ay(idx);

%% Settings

dV  = 5;        % Speed slice width
dAy = 0.02;     % Ay bin size

VLevels = 0:dV:floor(max(Speed));

%% Figure

figure('Color','w')
hold on
grid on
box on

cmap = turbo(length(VLevels));

%% Loop Through Speed Slices

for i = 1:length(VLevels)

    idxV = abs(Speed - VLevels(i)) <= dV/2;

    if nnz(idxV) < 30
        continue
    end

    %% Local Data

    AyLocal = abs(Ay(idxV));
    AxLocal = Ax(idxV);

    %% Ay Binning

    AyBins = 0:dAy:max(AyLocal);

    AyEnv = [];
    AxEnv = [];

    for k = 1:length(AyBins)-1

        idxBin = AyLocal >= AyBins(k) & ...
                 AyLocal <  AyBins(k+1);

        if nnz(idxBin) < 3
            continue
        end

        AyEnv(end+1) = mean(AyLocal(idxBin));

        % maximum acceleration for that Ay
        AxEnv(end+1) = max(AxLocal(idxBin));

    end

    %% Remove Garbage Tail

    [~,idxPeakAy] = max(AyEnv);

    AyEnv = AyEnv(1:idxPeakAy);
    AxEnv = AxEnv(1:idxPeakAy);

    %% Remove Negative Values

    keep = AxEnv > 0;

    AyEnv = AyEnv(keep);
    AxEnv = AxEnv(keep);

    if length(AyEnv) < 5
        continue
    end

    %% Smooth

    AyFine = linspace(min(AyEnv),max(AyEnv),200);

    AxFine = interp1(AyEnv,...
                     AxEnv,...
                     AyFine,...
                     'pchip');

    AxFine = smoothdata(AxFine,...
                        'sgolay',11);

    %% Mirror Left Side

    AyPlot = [-fliplr(AyFine) AyFine];
    AxPlot = [ fliplr(AxFine) AxFine];

    %% Plot

    plot3(AyPlot,...
          AxPlot,...
          VLevels(i)*ones(size(AyPlot)),...
          'Color',cmap(i,:),...
          'LineWidth',2)

end

%% Labels

xlabel('Lateral Acceleration A_y [G]')
ylabel('Longitudinal Acceleration A_x [G]')
zlabel('Vehicle Speed [km/h]')

title('Clean GGV Stack')

view(35,25)

colormap(turbo)

cb = colorbar;
cb.Label.String = 'Vehicle Speed [km/h]';

set(gca,...
    'FontSize',12,...
    'LineWidth',1.5)

axis tight
