clc;
clear;
close all;

%% 全局绘图属性设置
set(0, 'defaultTextInterpreter', 'latex');      % 默认使用 LaTeX 解释器
set(0, 'DefaultLineLineWidth', 0.8);             % 线条宽度设置为 0.8
set(0, 'DefaultAxesFontName', 'SimSun');         % 坐标轴字体设置为宋体
set(0, 'DefaultTextFontName', 'SimSun');         % 文本字体设置为宋体
set(0, 'DefaultAxesXGrid', 'on');                % 默认开启 X 轴网格
set(0, 'DefaultAxesYGrid', 'on');                % 默认开启 Y 轴网格
set(0, 'DefaultAxesZGrid', 'on');                % 默认开启 Z 轴网格

output_ratio_num = 9;

% config
plot_face_height = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 150, 200, 300, 400];
plot_line_height = [30, 100, 200, 400];
plot_hover_rotor_height = [30, 40, 50, 70, 90, 100, 110, 150, 200, 300, 400];
hover_rotor_speed = 789; 
R = 89; 
hover_thrust = 4.07; 

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
    
    force_z_cali = force_z_raw(1);    
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
        force_z_raw = data.('force_z_N_')';
        moment_z_raw = data.('moment_z_N_m_')';
        rotor_speed_raw = data.('rotorSpeed_rad_s_')';

        force_z_cali = force_z_raw(1);    
        moment_z_cali = moment_z_raw(1);

        thrust_tmp = -(force_z_raw(2:end) - force_z_cali); 
        moment_z_valid = moment_z_raw(2:end) - moment_z_cali;
        rotor_speed_valid = rotor_speed_raw(2:end);
        rotor_speed_valid_sqr = rotor_speed_valid.*rotor_speed_valid;
        
        k = mean(thrust_tmp./rotor_speed_valid_sqr);
        
        fig = figure('Name', sprintf('离地%dmm时推力随螺旋桨转速的关系', plot_line_height(i)));
        hold on;
        grid on; % 加入网格

        fig.Units = 'centimeters';
        figPos = [1, 1, 8, 5]; 
        fig.Position = figPos;  

        set(gcf, 'Units', 'centimeters');
        set(gcf, 'PaperUnits', 'centimeters'); 
        set(gcf, 'PaperPosition', [0, 0, figPos(3), figPos(4)]);
        set(gcf, 'PaperSize', [figPos(3), figPos(4)]); 
        
        plot(rotor_speed_valid_sqr, thrust_tmp, '.-', 'LineWidth', 0.8);
        x = [min(rotor_speed_valid_sqr), max(rotor_speed_valid_sqr)];   
        y = k * x;
        plot(x, y', 'LineWidth', 0.8);
        
        xlim([min(rotor_speed_sqr), max(rotor_speed_sqr)*1.002]);
        ylim([min(thrust)*0.95, max(thrust)*1.02]);
    
        legend('原始数据', '拟合曲线', 'Location', 'southeast', 'FontName', 'SimSun');
        xlabel('$\Omega^2 \mathrm{(rad^2 \cdot s^{-2})}$');
        ylabel('$T_{GE}\mathrm{(N)}$');
        
        k_exp = -6;
        fit_eq = sprintf('$T_{GE} = (%.2f \\times 10^{%d}) \\Omega^2$', k/10^k_exp, k_exp);
        text(0.2*x(1)+0.8*x(end), 0.07*y(1)+0.93*y(end), fit_eq, ...
             'FontSize', 11, 'FontName', 'SimSun', ...
             'HorizontalAlignment', 'right');  
        
        pdf_file_name = sprintf('pdf/thrust/rotor_thrust_%dmm.pdf', plot_line_height(i));
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
    
    force_z_cali = force_z_raw(1);    
    thrust_tmp = -(force_z_raw(2:end) - force_z_cali); 
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

times = 10;
a_vector = zeros(times + 1, 1);
b_vector = zeros(times + 1, 1);
error_vector = zeros(times + 1, 1);
a_vector(1) = 0.3;
b_vector(1) = -0.2;
error = hover_speed_thrust' - hover_thrust*(ones(length(plot_hover_rotor_height), 1) + a_vector(1)*exp(b_vector(1)*h_R'));
error_vector(1) = sum(error.^2);

for i = 1:times
    J = [-hover_thrust*exp(b_vector(i)*h_R'), -hover_thrust*a_vector(i)*h_R'.*(exp(b_vector(i)*h_R'))];
    delta = - (J'*J)\J'*error;
    a_vector(i + 1) = a_vector(i) + delta(1);
    b_vector(i + 1) = b_vector(i) + delta(2);
    error = hover_speed_thrust' - hover_thrust*(ones(length(plot_hover_rotor_height), 1) + a_vector(i+1)*exp(b_vector(i+1)*h_R'));
    error_vector(i+1) = sum(error.^2);
end

fig = figure('Name', '拟合参数随迭代次数的变化');
hold on;
grid on;

fig.Units = 'centimeters';
figPos = [1, 1, 8, 5]; 
fig.Position = figPos;  

set(gcf, 'Units', 'centimeters');
set(gcf, 'PaperUnits', 'centimeters'); 
set(gcf, 'PaperPosition', [0, 0, figPos(3), figPos(4)]);
set(gcf, 'PaperSize', [figPos(3), figPos(4)]); 

iteration = 0:times;
h1 = plot(iteration, a_vector, '-*', 'LineWidth', 0.8);
xlabel('迭代次数', 'FontName', 'SimSun', 'Interpreter', 'none');
ylabel('$C_{TAmp}$');

yyaxis right;
h2 = plot(iteration, b_vector, '-o', 'LineWidth', 0.8);
ylabel('$C_{TExp}$');
ylim([-2, 0]);
legend([h1, h2], '$C_{TAmp}$', '$C_{TExp}$', 'Location', 'southeast', 'Interpreter', 'latex');

ax = gca;
ax.Units = 'centimeters';
ax.Position = [1.2, 1.0, figPos(3) - 2.7, figPos(4) - 1.2];
print(gcf, '-dpdf', '-r300', 'pdf/thrust/T_param-iter.pdf');

fig = figure('Name', '拟合误差随迭代次数的变化');
hold on;
grid on;

fig.Units = 'centimeters';
figPos = [1, 1, 8, 5]; 
fig.Position = figPos;  

set(gcf, 'Units', 'centimeters');
set(gcf, 'PaperUnits', 'centimeters'); 
set(gcf, 'PaperPosition', [0, 0, figPos(3), figPos(4)]);
set(gcf, 'PaperSize', [figPos(3), figPos(4)]); 

iteration = 0:times;
plot(iteration, error_vector, '.-', 'LineWidth', 0.8);

xlabel('迭代次数', 'FontName', 'SimSun', 'Interpreter', 'none');
ylabel('$\sum E_{TGE,i}^2\mathrm{(N^2)}$');

ax = gca;
ax.Units = 'centimeters';
ax.Position = [1.2, 1.0, figPos(3) - 2.0, figPos(4) - 1.2];
print(gcf, '-dpdf', '-r300', 'pdf/thrust/T_err_iter.pdf');

fig = figure('Name', '推力随离地高度的关系');
hold on;
grid on;

fig.Units = 'centimeters';
figPos = [1, 1, 12, 8]; 
fig.Position = figPos;  

set(gcf, 'Units', 'centimeters');
set(gcf, 'PaperUnits', 'centimeters'); 
set(gcf, 'PaperPosition', [0, 0, figPos(3), figPos(4)]);
set(gcf, 'PaperSize', [figPos(3), figPos(4)]); 
    
plot(h_R, hover_speed_thrust, '.-', 'LineWidth', 0.8);

x_range = (min(h_R):0.01:max(h_R));
C_amp = a_vector(1);
C_exp = b_vector(1);
y_fit = (C_amp * exp(C_exp * x_range) + 1) * hover_thrust;
plot(x_range, y_fit, '--', 'LineWidth', 0.8);

C_amp = a_vector(2);
C_exp = b_vector(2);
y_fit = (C_amp * exp(C_exp * x_range) + 1) * hover_thrust;
plot(x_range, y_fit, '-.', 'LineWidth', 0.8);

C_amp = a_vector(end);
C_exp = b_vector(end);
y_fit = (C_amp * exp(C_exp * x_range) + 1) * hover_thrust;
plot(x_range, y_fit, '-', 'LineWidth', 0.8);

xlabel('$h/R$');
ylabel('$T_{GE}\mathrm{(N)}$');
legend({'原始数据', '第1次迭代拟合曲线', '第2次迭代拟合曲线', '第10次拟合曲线'}, 'FontName', 'SimSun');

print(gcf, '-dpdf', '-r300', 'pdf/thrust/line_T-h.pdf');

%% 绘制推力-螺旋桨转速-离地高度关系图
rotor_speed_sqr_scaled = 0.001*rotor_speed_sqr;
rpm_min = min(rotor_speed_sqr_scaled) + 50;
rpm_max = max(rotor_speed_sqr_scaled) - 50;
height_min = min(all_height);
height_max = max(all_height);

rpm_grid = linspace(rpm_min, rpm_max, 50);      
height_grid = linspace(height_min, height_max, 100); 
[RPM, HEIGHT] = meshgrid(rpm_grid, height_grid);

THRUST_GRID = griddata(rotor_speed_sqr_scaled, all_height, thrust, RPM, HEIGHT, 'cubic');
RPM = RPM * 1000;
HEIGHT = HEIGHT / R;

figure('Name', '推力-螺旋桨转速-离地高度关系图');
set(gcf, 'Units', 'centimeters');
set(gcf, 'PaperUnits', 'centimeters'); 
figPos = [0, 0, 16, 12]; 
set(gcf, 'PaperPosition', figPos);
set(gcf, 'PaperSize', [figPos(3), figPos(4)]); 
hold on;
grid on;

surf(RPM, HEIGHT, THRUST_GRID, 'EdgeAlpha', 0.2, 'FaceAlpha', 0.8);
view(109, 46);       
contour3(RPM, HEIGHT, THRUST_GRID, 15, 'LineWidth', 0.8, 'Color', 'w');

xlabel('$\Omega^2 \mathrm{(rad^2 \cdot s^{-2})}$');
ylabel('$h/R$');
zlabel('$T_{GE}\mathrm{(N)}$');

print(gcf, '-dpdf', '-r300', 'pdf/thrust/surf_T-omega-h.pdf');