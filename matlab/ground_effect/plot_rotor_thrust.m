clc;
clear;
close all;

set(0, 'defaultTextInterpreter', 'latex'); % 设置全局默认解释器为latex

output_ratio_num = 9;

% config
plot_face_height = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 150, 200, 300, 400];% 绘制推力-转速-高度曲面的数据

plot_line_height = [30, 100,  200, 400];% 绘制推力-转速曲线的数据

plot_hover_rotor_height = [30, 40, 50, 70, 90, 100, 110, 150, 200, 300, 400];% 绘制推力-高度曲线的数据
hover_rotor_speed = 789; % 悬停转速(rad/s)
R = 89; % 风扇半径(m)
hover_thrust = 4.07; % 无遮挡时风扇悬停转速下的推力（N）

force_z = [];
moment_z = [];
rotor_speed_sqr = [];
force_z_matrix = [];
rotor_speed_matrix = [];

all_height = [];
for i = 1:length(plot_face_height)
    file_name = sprintf('%s%d%s', 'rotor_thrust_data/rotor_thrust_result_', plot_face_height(i), 'mm.csv');
    data = readtable(file_name);
    force_z_raw = data.('force_z_N_')';
    moment_z_raw = data.('moment_z_N_m_')';
    rotor_speed_raw = data.('rotorSpeed_rad_s_')';
    
    force_z_cali = force_z_raw(1);    % 第一个数据为未起浆采集到的数据，是校准数据
    moment_z_cali = moment_z_raw(1);
    
    force_z_valid = force_z_raw(2:end) - force_z_cali;
    moment_z_valid = moment_z_raw(2:end) - moment_z_cali;
    rotor_speed_valid = rotor_speed_raw(2:end);
    
    force_z = [force_z, force_z_valid];
    moment_z = [moment_z, moment_z_valid];
    
    rotor_speed_sqr = [rotor_speed_sqr, rotor_speed_valid.*rotor_speed_valid];
    height_tmp = plot_face_height(i) * ones(1, length(force_z_valid));
    all_height = [all_height, height_tmp];
end

thrust = -force_z;

% 绘制转速-推力关系图
for i = 1:length(plot_line_height)
    file_name = sprintf('%s%d%s', 'rotor_thrust_data/rotor_thrust_result_', plot_line_height(i), 'mm.csv');
    if isfile(file_name)
        data = readtable(file_name);
        % 正常处理
        force_z_raw = data.('force_z_N_')';
        moment_z_raw = data.('moment_z_N_m_')';
        rotor_speed_raw = data.('rotorSpeed_rad_s_')';

        force_z_cali = force_z_raw(1);    % 第一个数据为未起浆采集到的数据，是校准数据
        moment_z_cali = moment_z_raw(1);

        thrust_tmp = -(force_z_raw(2:end) - force_z_cali); % 推力沿z轴负方向
        moment_z_valid = moment_z_raw(2:end) - moment_z_cali;
        rotor_speed_valid = rotor_speed_raw(2:end);
        rotor_speed_valid_sqr = rotor_speed_valid.*rotor_speed_valid;
        
%         % 一次函数拟合
%         p = polyfit(rotor_speed_valid_sqr, thrust_tmp, 1);
%         k = p(1);
%         b = p(2);
        
        % 正比例函数拟合
        k = mean(thrust_tmp./rotor_speed_valid_sqr);
        
        fig = figure('Name', sprintf('离地%dmm时推力随螺旋桨转速的关系', plot_line_height(i)));
        hold on;

        % 调整窗口大小
        fig.Units = 'centimeters';
        figPos = [1, 1, 8, 5]; % [左, 下, 宽, 高]
        fig.Position = figPos;  % 

        % 调整纸张大小
        set(gcf, 'Units', 'centimeters');
        set(gcf, 'PaperUnits', 'centimeters'); % 统一单位为厘米
        set(gcf, 'PaperPosition', [0, 0, figPos(3), figPos(4)]);
        set(gcf, 'PaperSize', [figPos(3), figPos(4)]); % 将纸张大小设置为与图一致
        
        % 绘制曲线
        plot(rotor_speed_valid_sqr, thrust_tmp, '.-');
        
        % 绘制拟合直线
        x = [min(rotor_speed_valid_sqr), max(rotor_speed_valid_sqr)];   % 只需两个端点即可画直线
%         y = k * x + b;
        y = k * x;
        plot(x, y');
        
        % 设置坐标轴范围
        xlim([min(rotor_speed_sqr), max(rotor_speed_sqr)*1.002]);
        ylim([min(thrust)*0.95, max(thrust)*1.02]);
    
%         title(sprintf('$h = %d\\mathrm{mm}$', plot_line_height(i)));
        % 设置图例
        legend('原始数据', '拟合曲线', 'Location', 'southeast');
        xlabel('$\Omega^2 \mathrm{(rad^2 \cdot s^{-2})}$');
        ylabel('$T_{GE}\mathrm{(N)}$');
        
        % 标注拟合表达式
        k_exp = -6;
%         fit_eq = sprintf('$T = %.2f \\times 10^{%d} \\Omega^2 %+.3f$', k/10^exp, exp, b);
        fit_eq = sprintf('$T_{GE} = (%.2f \\times 10^{%d}) \\Omega^2$', k/10^k_exp, k_exp);
        text(0.2*x(1)+0.8*x(end), 0.07*y(1)+0.93*y(end), fit_eq, ...
             'FontSize', 11, ...
             'HorizontalAlignment', 'right');  % 右对齐（因为放在右侧）
        
        pdf_file_name = sprintf('rotor_thrust_%dmm.pdf', plot_line_height(i));
        print(gcf, '-dpdf', '-r300', pdf_file_name);
    else
        warning('文件 "%s" 不存在，已跳过读取。', file_name);
    end
end

%% 绘制悬停转速下，推力-高度关系图
hover_speed_thrust = [];
for i = 1:length(plot_hover_rotor_height)
    file_name = sprintf('%s%d%s', 'rotor_thrust_data/rotor_thrust_result_', plot_hover_rotor_height(i), 'mm.csv');
    data = readtable(file_name);
    force_z_raw = data.('force_z_N_')';
    rotor_speed_raw = data.('rotorSpeed_rad_s_')';
    
    force_z_cali = force_z_raw(1);    % 第一个数据为未起浆采集到的数据，是校准数据
    thrust_tmp = -(force_z_raw(2:end) - force_z_cali); % 推力沿z轴负方向
    rotor_speed_valid = rotor_speed_raw(2:end);
    rotor_speed_valid_sqr = rotor_speed_valid.*rotor_speed_valid;
    
    p = polyfit(rotor_speed_valid_sqr, thrust_tmp, 1);
    k = p(1);
    b = p(2);
    x = [6e5, 8e5];
    y = k * x + b;
    
    hover_speed_thrust = [hover_speed_thrust, k * (hover_rotor_speed * hover_rotor_speed) + b];
end
h_R = plot_hover_rotor_height / R;
C_GE = (hover_speed_thrust / hover_thrust) - 1;
% 设C_GE和h_R的关系为y=a*exp(b*h_R)
% 设T_GE和h_R的关系为T_GE=T*(1 + a*exp(b*h_R))
times = 10;
a_vector = zeros(times + 1, 1);
b_vector = zeros(times + 1, 1);
error_vector = zeros(times + 1, 1);
a_vector(1) = 0.3;
b_vector(1) = -0.2;
% error = C_GE' - a_vector(1)*exp(b_vector(1)*h_R');
error = hover_speed_thrust' - hover_thrust*(ones(length(plot_hover_rotor_height), 1) + a_vector(1)*exp(b_vector(1)*h_R'));
error_vector(1) = sum(error.^2);
% 高斯牛顿法迭代拟合
for i = 1:times
%     J = [-exp(b_vector(i)*h_R'), -a_vector(i)*h_R'.*(exp(b_vector(i)*h_R'))];
    J = [-hover_thrust*exp(b_vector(i)*h_R'), -hover_thrust*a_vector(i)*h_R'.*(exp(b_vector(i)*h_R'))];
    delta = - (J'*J)\J'*error;
    a_vector(i + 1) = a_vector(i) + delta(1);
    b_vector(i + 1) = b_vector(i) + delta(2);
%     error = C_GE' - a_vector(i+1)*exp(b_vector(i+1)*h_R');
    error = hover_speed_thrust' - hover_thrust*(ones(length(plot_hover_rotor_height), 1) + a_vector(i+1)*exp(b_vector(i+1)*h_R'));
    error_vector(i+1) = sum(error.^2);
end

fig = figure('Name', '拟合参数随迭代次数的变化');
hold on;

% 调整窗口大小
fig.Units = 'centimeters';
figPos = [1, 1, 8, 5]; % [左, 下, 宽, 高]
fig.Position = figPos;  % 

% 调整纸张大小
set(gcf, 'Units', 'centimeters');
set(gcf, 'PaperUnits', 'centimeters'); % 统一单位为厘米
set(gcf, 'PaperPosition', [0, 0, figPos(3), figPos(4)]);
set(gcf, 'PaperSize', [figPos(3), figPos(4)]); % 将纸张大小设置为与图一致

iteration = 0:times;
h1 = plot(iteration, a_vector, 'b-*');
xlabel('迭代次数');
ylabel('$C_{TAmp}$', 'Interpreter', 'latex');
grid on;

% 激活右侧 y 轴，并绘制第二条曲线
yyaxis right;
h2 = plot(iteration, b_vector, 'r-o');
ylabel('$C_{TExp}$', 'Interpreter', 'latex');
ylim([-2, 0]);
legend([h1, h2], '$C_{TAmp}$', '$C_{TExp}$', 'Interpreter', 'latex', 'Location', 'southeast');

ax = gca;
ax.Units = 'centimeters';
ax.Position = [1.2, 1.0, figPos(3) - 2.7, figPos(4) - 1.2];
print(gcf, '-dpdf', '-r300', 'T_param-iter.pdf');

fig = figure('Name', '拟合误差随迭代次数的变化');
hold on;

% 调整窗口大小
fig.Units = 'centimeters';
figPos = [1, 1, 8, 5]; % [左, 下, 宽, 高]
fig.Position = figPos;  % 

% 调整纸张大小
set(gcf, 'Units', 'centimeters');
set(gcf, 'PaperUnits', 'centimeters'); % 统一单位为厘米
set(gcf, 'PaperPosition', [0, 0, figPos(3), figPos(4)]);
set(gcf, 'PaperSize', [figPos(3), figPos(4)]); % 将纸张大小设置为与图一致

iteration = 0:times;
plot(iteration, error_vector, '.-');

xlabel('迭代次数');
ylabel('$\sum E_{TGE,i}^2\mathrm{(N^2)}$');

ax = gca;
ax.Units = 'centimeters';
ax.Position = [1.2, 1.0, figPos(3) - 2.0, figPos(4) - 1.2];
print(gcf, '-dpdf', '-r300', 'T_err_iter.pdf');

fig = figure('Name', '推力随离地高度的关系');
hold on;

% 调整窗口大小
fig.Units = 'centimeters';
figPos = [1, 1, 12, 8]; % [左, 下, 宽, 高]
fig.Position = figPos;  % 

% 调整纸张大小
set(gcf, 'Units', 'centimeters');
set(gcf, 'PaperUnits', 'centimeters'); % 统一单位为厘米
set(gcf, 'PaperPosition', [0, 0, figPos(3), figPos(4)]);
set(gcf, 'PaperSize', [figPos(3), figPos(4)]); % 将纸张大小设置为与图一致
    
plot(h_R, hover_speed_thrust, '.-');
print(gcf, '-dpdf', '-r300', 'line_T-h.pdf');

x = (min(h_R):0.01:max(h_R));
C_amp = a_vector(1);
C_exp = b_vector(1);
y = (C_amp * exp(C_exp * x) + 1) * hover_thrust;
plot(x, y, '--');

x = (min(h_R):0.01:max(h_R));
C_amp = a_vector(2);
C_exp = b_vector(2);
y = (C_amp * exp(C_exp * x) + 1) * hover_thrust;
plot(x, y, '-.');

x = (min(h_R):0.01:max(h_R));
C_amp = a_vector(end);
C_exp = b_vector(end);
y = (C_amp * exp(C_exp * x) + 1) * hover_thrust;
plot(x, y, '-');

xlabel('$h/R$');
ylabel('$T_{GE}\mathrm{(N)}$');

legend('原始数据', '第1次迭代拟合曲线', '第2次迭代拟合曲线', '第10次拟合曲线');

print(gcf, '-dpdf', '-r300', 'line_T-h.pdf');

%% 绘制推力-螺旋桨转速-离地高度关系图
rotor_speed_sqr = 0.001*rotor_speed_sqr;
rpm_min = min(rotor_speed_sqr) + 50;
rpm_max = max(rotor_speed_sqr) - 50;
height_min = min(all_height);
height_max = max(all_height);


% 创建网格点（调整网格密度）
rpm_grid = linspace(rpm_min, rpm_max, 50);      % RPM网格
height_grid = linspace(height_min, height_max, 100); % 高度网格
[RPM, HEIGHT] = meshgrid(rpm_grid, height_grid);

% 插值处理（关键步骤）
% 方法1：griddata插值（适用于散乱数据）
THRUST_GRID = griddata(rotor_speed_sqr, all_height, thrust, RPM, HEIGHT, 'cubic');
MOMENT_GRID = griddata(rotor_speed_sqr, all_height, moment_z, RPM, HEIGHT, 'cubic');
RPM = RPM * 1000;
HEIGHT = HEIGHT / R;

% 方法2：如果数据量足够，也可以使用scatteredInterpolant
% F = scatteredInterpolant(rotor_speed_sqr', all_height', thrust', 'natural');
% THRUST_GRID = F(RPM, HEIGHT);

% 绘制3D曲面图
figure('Name', '推力-螺旋桨转速-离地高度关系图');
set(gcf, 'Units', 'centimeters');
set(gcf, 'PaperUnits', 'centimeters'); % 统一单位为厘米
figPos = [0, 0, 16, 12]; % PDF尺寸280 × 396 mm (纵向)
set(gcf, 'PaperPosition', figPos);
set(gcf, 'PaperSize', [figPos(3), figPos(4)]); % 将纸张大小设置为与图一致
hold on;

% 主曲面
surf(RPM, HEIGHT, THRUST_GRID, 'EdgeAlpha', 0.2, 'FaceAlpha', 0.8);
view(109, 46);            % 设置方位角 az 和仰角 el（单位：度）
hold on;

% 生成网格
contour3(RPM, HEIGHT, THRUST_GRID, 15, 'LineWidth', 1.5, 'Color', 'w');

% 绘制图例
xlabel('$\Omega^2 \mathrm{(rad^2 \cdot s^{-2})}$');
ylabel('$h/R$');
zlabel('$T_{GE}\mathrm{(N)}$');

% 输出pdf
print(gcf, '-dpdf', '-r300', 'surf_T-omega-h.pdf');

%% 绘制扭矩3D曲面图
% figure('Name', '控制力矩-螺旋桨转速-离地高度关系图');
% 
% % 主曲面
% surf(RPM, HEIGHT, MOMENT_GRID, 'EdgeAlpha', 0.2, 'FaceAlpha', 0.8);
% hold on;
% 
% % 生成网格
% contour3(RPM, HEIGHT, MOMENT_GRID, 15, 'LineWidth', 1.5, 'Color', 'w');


