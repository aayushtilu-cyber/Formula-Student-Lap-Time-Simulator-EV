clc
close all

%% Vehicle limits

AxAcc = 0.335;     % acceleration limit
AxBrk = 0.58;      % braking limit
AyMax = 1.00;      % lateral limit

n = 2.2;

Ay = linspace(-AyMax,AyMax,400);

%% Acceleration envelope

Ax_Pos = AxAcc .* ...
         (1 - abs(Ay./AyMax).^n).^(1/n);

%% Braking envelope

Ax_Neg = -AxBrk .* ...
          (1 - abs(Ay./AyMax).^n).^(1/n);

%% Plot

figure
hold on
grid on

scatter(GGV_Table.Ay_G,...
        GGV_Table.Ax_G,...
        8,...
        [0.75 0.75 0.75],...
        'filled')

plot(Ay,...
     Ax_Pos,...
     'r',...
     'LineWidth',4)

plot(Ay,...
     Ax_Neg,...
     'b',...
     'LineWidth',4)

xlabel('A_y [G]')
ylabel('A_x [G]')

title('Professional GG Diagram')

legend('Operating Points',...
       'Acceleration Limit',...
       'Braking Limit',...
       'Location','best')

xlim([-1.1 1.1])
ylim([-0.7 0.45])
