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

% 螺旋桨受到的扭矩是负的
height = [15, 25, 40, 90, 100, 200, 300];
target_angles = [-20, -18, -16, -14, -12, -10, -8, -6, -4, -2, 0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20]'*pi/180;
fit_line_height = [15, 25, 40, 90, 100, 200, 300];
K_cv = 0.84;
l_2 = 0.05685;
R = 89;
moment_z = zeros(length(target_angles), length(height));
force_z = zeros(length(target_angles), length(height));
for i = 1:length(height)
    file_name = sprintf('%s%d%s', 'cs_torque_data/force_sensor_', height(i), 'mm_processed.csv');
    data = readtable(file_name);
    moment_z(:, i) = data.('moment_z');
    force_z(:, i) = data.('force_z');
end

moment_range = [min(moment_z(:)), max(moment_z(:))];

% 假设你的数据格式：
% diatance: 离地高度向量 (1×m)
% target_angles: 舵面角度向量 (1×n)
% moment: 力矩矩阵 (m×n)，moment(i,j) 对应 height(i) 和 angle(j)

% 生成网格
[Height, Angle] = meshgrid(height, target_angles);

% 创建曲面图
fig = figure('Name', 'moment-h-delta');
% 调整窗口大小
fig.Units = 'centimeters';
figPos = [1, 1, 12, 8]; % [左, 下, 宽, 高]
fig.Position = figPos;  % 

% 调整纸张大小
set(gcf, 'Units', 'centimeters');
set(gcf, 'PaperUnits', 'centimeters'); % 统一单位为厘米
set(gcf, 'PaperPosition', [0, 0, figPos(3), figPos(4)]);
set(gcf, 'PaperSize', [figPos(3), figPos(4)]); % 将纸张大小设置为与图一致

% 基本曲面图
% subplot(2,2,1);
h_R = Height / R;
surf(h_R, Angle, moment_z);
xlabel('$h/R$', 'FontSize', 10);
ylabel('$\delta_c \mathrm{(rad)}$', 'FontSize', 10);
zlabel('$M_{z}^b \mathrm{(N \cdot m)}$', 'FontSize', 10);
view(16, 19);
grid on;
print(gcf, '-dpdf', '-r300', 'moment-h-delta.pdf');

%% 各高度下扭矩-舵面角度
k_cvGE = zeros(length(fit_line_height), 1);
zero_moment = zeros(length(fit_line_height), 1);
for i = 1:length(fit_line_height)
    file_name = sprintf('%s%d%s', 'cs_torque_data/force_sensor_', height(i), 'mm_processed.csv');
    data = readtable(file_name);
    moment_z(:, i) = data.('moment_z');
    
    fig = figure('Name', sprintf('%dmm扭矩-舵面角度', fit_line_height(i)));
    hold on;
    
    % 调整窗口大小
    fig.Units = 'centimeters';
    figPos = [1, 1, 8, 5]; % [左, 下, 宽, 高]
    fig.Position = figPos;  % 

    % 调整窗口大小
    set(gcf, 'Units', 'centimeters');
    set(gcf, 'PaperUnits', 'centimeters'); % 统一单位为厘米
    set(gcf, 'PaperPosition', [0, 0, figPos(3), figPos(4)]);
    set(gcf, 'PaperSize', [figPos(3), figPos(4)]); % 将纸张大小设置为与图一致

    p = polyfit(target_angles, moment_z(:, i), 1);
    k = p(1);
    b = p(2);
    
    x = target_angles;
    y = k * x + b;
    
    k_cvGE(i) = k/4/l_2;
    zero_moment(i) = b;
        
    plot(target_angles, moment_z(:, i), '.-');
    plot(x, y);
    % 设置坐标轴范围
    xlim([min(target_angles)*1.05, max(target_angles)*1.05]);
    ylim(moment_range*1.05);
    % 设置图例
    legend('原始数据', '拟合曲线', 'Location', 'southeast');
    xlabel('$\delta \mathrm{(rad)}$');
    ylabel('$M_{z}^b\mathrm{(N \cdot m)}$');
    
    ax = gca;
    ax.Units = 'centimeters';
    ax.Position = [1.4, 1.0, figPos(3) - 2.0, figPos(4) - 1.2];

    pdf_file_name = sprintf('cv_moment_%dmm.pdf', fit_line_height(i));
    print(gcf, '-dpdf', '-r300', pdf_file_name);
end

fig = figure('Name', '无输出扭矩-高度');
hold on;
    
% 调整窗口大小
fig.Units = 'centimeters';
figPos = [1, 1, 8, 5]; % [左, 下, 宽, 高]
fig.Position = figPos;  % 

% 调整窗口大小
set(gcf, 'Units', 'centimeters');
set(gcf, 'PaperUnits', 'centimeters'); % 统一单位为厘米
set(gcf, 'PaperPosition', [0, 0, figPos(3), figPos(4)]);
set(gcf, 'PaperSize', [figPos(3), figPos(4)]); % 将纸张大小设置为与图一致

h_R = fit_line_height / R;
plot(h_R, zero_moment, '.-');
xlim([0, max(h_R)*1.1]);
ylim(moment_range * 1.8);

% 填充最大最小值
x_fill = [-10, 10, 10, -10];
y_fill = [moment_range(1), moment_range(1), moment_range(2), moment_range(2)];
fill(x_fill, y_fill, 'r', 'FaceAlpha', 0.3, 'EdgeColor', 'none');
% 添加水平边界线
yline(moment_range(2), 'r--');
yline(moment_range(1), 'r--');

legend('舵面偏转角为零时Z轴力矩', 'Z轴力矩输出范围', 'Location', 'southeast', 'Interpreter', 'latex')

% 设置图例
xlabel('$h/R$');
ylabel('$M_{z}^b\mathrm{(N \cdot m)}$');

% 设置坐标轴长度
ax = gca;
ax.Units = 'centimeters';
ax.Position = [1.4, 1.0, figPos(3) - 2.0, figPos(4) - 1.2];

print(gcf, '-dpdf', '-r300', 'zero_output_moment.pdf');

%% 拟合扭矩斜率-高度
h_R = fit_line_height / R;
y_cvGE = 1 - (k_cvGE / K_cv);
% 设y_cvGE和h_R的关系为y_cvGE=a*exp(b*h_R)
times = 10;
a_vector = zeros(times + 1, 1);
b_vector = zeros(times + 1, 1);
error_vector = zeros(times + 1, 1);
a_vector(1) = 0.3;
b_vector(1) = -1.1;
error = y_cvGE - a_vector(1)*exp(b_vector(1)*h_R');
error_vector(1) = sum(error.^2);
% 高斯牛顿法迭代拟合
for i = 1:times
    J = [-exp(b_vector(i)*h_R'), -a_vector(i)*h_R'.*(exp(b_vector(i)*h_R'))];
    delta = - (J'*J)\J'*error;
    a_vector(i + 1) = a_vector(i) + delta(1);
    b_vector(i + 1) = b_vector(i) + delta(2);
    error = y_cvGE - a_vector(i+1)*exp(b_vector(i+1)*h_R');
    error_vector(i+1) = sum(error.^2);
end

fig = figure('Name', 'K_cv-高度');
% 调整窗口大小
fig.Units = 'centimeters';
figPos = [1, 1, 12, 8]; % [左, 下, 宽, 高]
fig.Position = figPos;  % 

% 调整纸张大小
set(gcf, 'Units', 'centimeters');
set(gcf, 'PaperUnits', 'centimeters'); % 统一单位为厘米
set(gcf, 'PaperPosition', [0, 0, figPos(3), figPos(4)]);
set(gcf, 'PaperSize', [figPos(3), figPos(4)]); % 将纸张大小设置为与图一致
hold on;
plot(h_R, k_cvGE, '.-');

x = (min(h_R):0.01:max(h_R));
C_amp = a_vector(1);
C_exp = b_vector(1);
y = (1 - C_amp * exp(C_exp * x)) * K_cv;
plot(x, y, '--');

x = (min(h_R):0.01:max(h_R));
C_amp = a_vector(2);
C_exp = b_vector(2);
y = (1 - C_amp * exp(C_exp * x)) * K_cv;
plot(x, y, '-.');

x = (min(h_R):0.01:max(h_R));
C_amp = a_vector(end);
C_exp = b_vector(end);
y = (1 - C_amp * exp(C_exp * x)) * K_cv;
plot(x, y, '-');

xlabel('$h/R$');
ylabel('$K_{\mathrm{cvGE}}(\mathrm{N / rad})$');
legend('原始数据', '第1次迭代拟合曲线', '第2次迭代拟合曲线', '第10次迭代拟合曲线', 'Location', 'southeast');
print(gcf, '-dpdf', '-r300', 'K_cv-h.pdf');

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
ylabel('$\sum E_{cvGE,i}^2 \mathrm{(N^2\cdot rad^{-2})}$');
xlabel('迭代次数');
ax = gca;
ax.Units = 'centimeters';
ax.Position = [1.2, 1.0, figPos(3) - 2.0, figPos(4) - 1.2];

print(gcf, '-dpdf', '-r300', 'errr-iter.pdf');

% 绘制参数迭代曲线
fig = figure('Name', '参数迭代曲线');
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

h1 = plot(iteration, a_vector, '-*');
xlabel('迭代次数');
ylabel('$C_{cvAmp}$', 'Interpreter', 'latex');
grid on;

% 激活右侧 y 轴，并绘制第二条曲线
yyaxis right;
h2 = plot(iteration, b_vector, '-o');
ylabel('$C_{cvExp}$', 'Interpreter', 'latex');
legend([h1, h2], '$C_{cvAmp}$', '$C_{cvExp}$', 'Interpreter', 'latex', 'Location', 'southeast');

ax = gca;
ax.Units = 'centimeters';
ax.Position = [1.2, 1.0, figPos(3) - 2.7, figPos(4) - 1.2];
print(gcf, '-dpdf', '-r300', 'cv_param-iter.pdf');
