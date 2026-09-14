clc
clear
close all

%% ==================================================
% GGV SWEEP SETTINGS
%% ==================================================

SpeedList = [5 10 15 20 25 30];

ThrottleList = 0:0.25:1;

BrakeList = 0:0.25:1;

SteerList = 0:0.5:8;

Rw = 0.3;

GGV = [];

%% ==================================================
% ACCELERATION CASES
%% ==================================================

for V0 = SpeedList

    fprintf('\nSpeed = %.1f m/s\n',V0);

    for Thr = ThrottleList

        for SteerDeg = SteerList

            Omega0 = V0/Rw;

            Accelcmd = Thr;
            Decelcmd = 0;

            Steer_rad = deg2rad(SteerDeg);

            assignin('base','V0',V0);
            assignin('base','Omega0',Omega0);

            assignin('base','Accelcmd',Accelcmd);
            assignin('base','Decelcmd',Decelcmd);

            assignin('base','Steer_rad',Steer_rad);

            simOut = sim('LTS_GGV');

            Ax = simOut.Ax;
            Ay = simOut.Ay;
            Vx = simOut.Vx;
            Vy = simOut.Vy;

            AlphaFL = simOut.AlphaFL;
            AlphaFR = simOut.AlphaFR;
            AlphaRL = simOut.AlphaRL;
            AlphaRR = simOut.AlphaRR;

            N = length(Ax);

            idx = round(0.90*N):N;

            Ax_ss = mean(Ax(idx));
            Ay_ss = mean(Ay(idx));

            GGV = [GGV;
                   V0 ...
                   Thr ...
                   0 ...
                   SteerDeg ...
                   Ax_ss ...
                   Ay_ss];

            fprintf('ACC  V=%2.0f Thr=%4.2f St=%4.1f Ax=%6.3f Ay=%6.3f\n',...
                V0,Thr,SteerDeg,Ax_ss,Ay_ss);

        end
    end
end

%% ==================================================
% BRAKING CASES
%% ==================================================

for V0 = SpeedList

    fprintf('\nBrake Sweep Speed = %.1f\n',V0);

    for Brk = BrakeList

        for SteerDeg = SteerList

            Omega0 = V0/Rw;

            Accelcmd = 0;
            Decelcmd = Brk;

            Steer_rad = deg2rad(SteerDeg);

            assignin('base','V0',V0);
            assignin('base','Omega0',Omega0);

            assignin('base','Accelcmd',Accelcmd);
            assignin('base','Decelcmd',Decelcmd);

            assignin('base','Steer_rad',Steer_rad);

            simOut = sim('LTS_GGV');

            Ax = simOut.Ax;
            Ay = simOut.Ay;

            N = length(Ax);

            idx = round(0.90*N):N;

            Ax_ss = mean(Ax(idx));
            Ay_ss = mean(Ay(idx));

            GGV = [GGV;
                   V0 ...
                   0 ...
                   Brk ...
                   SteerDeg ...
                   Ax_ss ...
                   Ay_ss];

            fprintf('BRK  V=%2.0f Brk=%4.2f St=%4.1f Ax=%6.3f Ay=%6.3f\n',...
                V0,Brk,SteerDeg,Ax_ss,Ay_ss);

        end
    end
end

%% ==================================================
% MIRROR LEFT/RIGHT
%% ==================================================

GGV_Left = GGV;

GGV_Left(:,6) = -GGV_Left(:,6);

GGV_All = [GGV ; GGV_Left];

%% ==================================================
% TABLE
%% ==================================================

GGV_Table = array2table(GGV_All,...
'VariableNames',...
{'Speed',...
'Throttle',...
'Brake',...
'Steering',...
'Ax_G',...
'Ay_G'});

disp(GGV_Table)

%% ==================================================
% LIMITS
%% ==================================================

fprintf('\n');
fprintf('Maximum Ax = %.3f G\n',max(GGV_All(:,5)));

fprintf('Minimum Ax = %.3f G\n',min(GGV_All(:,5)));

fprintf('Maximum Ay = %.3f G\n',max(GGV_All(:,6)));

fprintf('Minimum Ay = %.3f G\n',min(GGV_All(:,6)));

%% ==================================================
% GGV CLOUD
%% ==================================================

figure

scatter(GGV_All(:,6),...
        GGV_All(:,5),...
        12,...
        GGV_All(:,1),...
        'filled')

xlabel('Ay [G]')
ylabel('Ax [G]')

title('GGV Diagram')

grid on
colorbar

%% ==================================================
% SAVE
%% ==================================================

save('GGV_Data.mat',...
     'GGV_Table',...
     'GGV_All')
