%% Professional Lap Time Replay (No Steering Angle Data)
% Requires variables from KariTrack(1).mat
clc;

%% -------------------- USER CONFIGURATION --------------------
% Prompt user for saving video (1 = Save Video, 0 = Real-time Display Only)
saveVideoOption = input('Do you want to export the video to file? (1 = Yes, 0 = No): ');

% Multiplier for replay speed (Increase to make animation faster)
speedUpFactor = 6; 

%% -------------------- DATA PREPARATION --------------------
VehicleX   = x_veh(:);
VehicleY   = y_veh(:);
VehicleYaw = YawVeh(:);

% Using X_sim1 for Ax and Y_sim1 for Ay
Ax         = X_sim1(:);   % Longitudinal acceleration
Ay         = Y_sim1(:);   % Lateral acceleration

% Map for G-G Diagram: X-axis = Lateral (Ay), Y-axis = Longitudinal (Ax)
GGx        = Ay; 
GGy        = Ax; 

SpeedVeh   = speed_path(:);
TimeVeh    = t_data(:);

% Track centerline & boundary vectors
pX     = pathX(:);
pY     = pathY(:);
lX     = leftX(:);
lY     = leftY(:);
rX     = rightX(:);
rY     = rightY(:);

N = min([length(VehicleX), length(VehicleY), length(VehicleYaw), ...
         length(SpeedVeh), length(TimeVeh), length(GGx), length(GGy)]);

VehicleX   = VehicleX(1:N);
VehicleY   = VehicleY(1:N);
VehicleYaw = VehicleYaw(1:N);
SpeedVeh   = SpeedVeh(1:N);
TimeVeh    = TimeVeh(1:N);
GGx        = GGx(1:N);
GGy        = GGy(1:N);
Ax         = Ax(1:N);
Ay         = Ay(1:N);

%% -------------------- FIGURE SETUP --------------------
fig = figure('Color','w','Position',[50 50 1920 1080]);
set(fig, 'Renderer', 'opengl');

%% 1. TRACK ANIMATION PANEL
axTrack = axes('Position', [0.12 0.22 0.50 0.70]);
hold(axTrack, 'on');

% Draw black asphalt track surface
patch([lX; flipud(rX)], ...
      [lY; flipud(rY)], ...
      [0.15 0.15 0.15], ...
      'EdgeColor', 'none', 'Parent', axTrack);

% Track boundaries (White solid lines)
plot(axTrack, lX, lY, 'w-', 'LineWidth', 1.5);
plot(axTrack, rX, rY, 'w-', 'LineWidth', 1.5);

% Full centerline track (White dashed line)
plot(axTrack, pX, pY, 'w--', 'LineWidth', 1.2);

% Speed-colored trace (Initialize with NaN matrix)
hCarTrail = surface(axTrack, NaN(2,2), NaN(2,2), zeros(2,2), NaN(2,2), ...
                    'FaceColor', 'none', 'EdgeColor', 'interp', 'LineWidth', 3.5);
colormap(axTrack, turbo);

% Lock Colorbar Limits permanently
caxis(axTrack, [min(SpeedVeh) max(SpeedVeh)]);
cb = colorbar(axTrack, 'southoutside');
cb.Position = [0.15 0.08 0.44 0.03];
cb.Label.String = 'Speed [km/h]';
cb.FontWeight = 'bold';

axis(axTrack, 'equal');
grid(axTrack, 'on');
box(axTrack, 'on');
title(axTrack, 'LAP ANIMATION', 'FontSize', 16, 'FontWeight', 'bold');

% Vehicle marker
carMarker = plot(axTrack, VehicleX(1), VehicleY(1), 'go', ...
                 'MarkerFaceColor', 'g', 'MarkerSize', 10);

%% 2. TELEMETRY OVERLAY TABLE
telemetryBox = annotation('textbox', [0.01 0.78 0.10 0.14], ...
    'String', '', ...
    'BackgroundColor', 'w', ...
    'EdgeColor', 'k', ...
    'LineWidth', 1.5, ...
    'FontName', 'Consolas', ...
    'FontSize', 10, ...
    'FitBoxToText', 'off');

%% 3. SPEED PROFILE PANEL
axSpeed = axes('Position', [0.68 0.56 0.28 0.36]);
hold(axSpeed, 'on');

plot(axSpeed, TimeVeh, SpeedVeh, 'Color', [0.7 0.7 0.7], 'LineWidth', 1.5, 'DisplayName', 'Full lap');
hProgressSpeed = plot(axSpeed, TimeVeh(1), SpeedVeh(1), 'b-', 'LineWidth', 2.5, 'DisplayName', 'Current progress');
cursorSpeed    = plot(axSpeed, TimeVeh(1), SpeedVeh(1), 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 8, 'DisplayName', 'Current');

grid(axSpeed, 'on');
box(axSpeed, 'on');
title(axSpeed, 'SPEED PROFILE', 'FontSize', 14, 'FontWeight', 'bold');
xlabel(axSpeed, 'Time [s]');
ylabel(axSpeed, 'Speed [km/h]');
xlim(axSpeed, [min(TimeVeh) max(TimeVeh)]);
ylim(axSpeed, [0 max(SpeedVeh)*1.1]);
legend(axSpeed, 'Location', 'southeast');

%% 4. G-G DIAGRAM PANEL
axGG = axes('Position', [0.68 0.08 0.28 0.36]);
hold(axGG, 'on');

th = linspace(0, 2*pi, 300);
plot(axGG, cos(th), sin(th), 'k--', 'LineWidth', 0.8);
plot(axGG, 0.5*cos(th), 0.5*sin(th), 'k:', 'LineWidth', 0.5);
plot(axGG, 1.5*cos(th), 1.5*sin(th), 'k:', 'LineWidth', 0.5);

xline(axGG, 0, 'k-', 'Alpha', 0.3);
yline(axGG, 0, 'k-', 'Alpha', 0.3);

GGhist  = plot(axGG, NaN, NaN, '.', 'Color', [0.3 0.5 0.9], 'MarkerSize', 8);
GGpoint = plot(axGG, GGx(1), GGy(1), 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 8);

grid(axGG, 'on');
box(axGG, 'on');
axis(axGG, 'equal');
title(axGG, 'G-G DIAGRAM', 'FontSize', 14, 'FontWeight', 'bold');
xlabel(axGG, 'Ay (Lateral) [g]');
ylabel(axGG, 'Ax (Longitudinal) [g]');

maxG = max(1.5, max(abs([GGx; GGy])) * 1.15);
xlim(axGG, [-maxG maxG]);
ylim(axGG, [-maxG maxG]);

%% -------------------- ANIMATION LOOP & VIDEO WRITER --------------------
fps = 60;
dt = mean(diff(TimeVeh)); 
frameStep = max(1, round(speedUpFactor / (fps * dt))); 

if saveVideoOption == 1
    if exist('video', 'var')
        clear video;
    end
    outputFilename = 'Professional_Lap_Replay.mp4';
    video = VideoWriter(outputFilename, 'MPEG-4');
    video.FrameRate = fps;
    open(video);
end

for i = 1:frameStep:N
    % Update Car Position
    set(carMarker, 'XData', VehicleX(i), 'YData', VehicleY(i));
    
    % Update Speed-Colored Path Trail
    if i >= 2
        curX = VehicleX(1:i);
        curY = VehicleY(1:i);
        curS = SpeedVeh(1:i);
        
        set(hCarTrail, ...
            'XData', [curX curX], ...
            'YData', [curY curY], ...
            'ZData', zeros(length(curX), 2), ...
            'CData', [curS curS]);
    end
    
    % Update Speed Profile Progress
    set(hProgressSpeed, 'XData', TimeVeh(1:i), 'YData', SpeedVeh(1:i));
    set(cursorSpeed, 'XData', TimeVeh(i), 'YData', SpeedVeh(i));
    
    % Update G-G Diagram
    set(GGhist, 'XData', GGx(1:i), 'YData', GGy(1:i));
    set(GGpoint, 'XData', GGx(i), 'YData', GGy(i));
    
    % Update Telemetry Box Text (Without Steering Angle)
    telemetryBox.String = sprintf([ ...
        'TIME   : %6.2f s\n' ...
        'SPEED  : %6.1f km/h\n' ...
        'Ax     : %+6.2f g\n' ...
        'Ay     : %+6.2f g\n' ...
        'LAP    : %6.1f %%'], ...
        TimeVeh(i), ...
        SpeedVeh(i), ...
        Ax(i), ...
        Ay(i), ...
        (i / N) * 100);
    
    drawnow limitrate;
    
    if saveVideoOption == 1
        frame = getframe(fig);
        writeVideo(video, frame);
    end
end

if saveVideoOption == 1
    close(video);
    disp(['Video successfully exported to: ', outputFilename]);
else
    disp('Animation playback completed.');
end