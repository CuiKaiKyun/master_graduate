%% Drone Flight Data Visualization
clear; clc; close all;

% --- 参数配置 ---
file_name = 'ge_flight_height_data/flight_data_anti_yaw_200mm.csv';
output_folder = './'; 
fig_width = 16;       % 图像宽度 (cm)
fig_height = 12;      % 图像高度 (cm)

% 颜色定义
resp_color = [0, 0.4470, 0.7410];      % 蓝色 (实测值)
setpoint_color = [0.8500, 0.3250, 0.0980]; % 橙红 (目标值)

%% 1. 数据处理
if ~exist(file_name, 'file'), error('找不到文件: %s', file_name); end
raw_text = fileread(file_name);
lines = splitlines(raw_text);
lines(cellfun('isempty', lines)) = []; 

% 验证并清洗数据行
expected_commas = length(strfind(lines{1}, ','));
valid_idx = cellfun(@(x) length(strfind(x, ',')) == expected_commas, lines);
clean_lines = lines(valid_idx);

temp_file = 'temp_flight_data.csv';
fid = fopen(temp_file, 'w');
fprintf(fid, '%s\n', clean_lines{:});
fclose(fid);

opts = detectImportOptions(temp_file);
data = readtable(temp_file, opts);

try
    % 尝试通过列名提取 (不同MATLAB版本可能对空格有不同的转义)
    raw_time = data.('time');
    
    raw_targetGyroX = data.('target_gyro_x');
    raw_targetGyroY = data.('target_gyro_y');
    raw_targetGyroZ = data.('target_gyro_z');
    raw_gyroX = data.('gyro_x');
    raw_gyroY = data.('gyro_y');
    raw_gyroZ = data.('gyro_z');

    raw_targetAngleX = data.('target_angle_x');
    raw_targetAngleY = data.('target_angle_y');
    raw_targetAngleZ = data.('target_angle_z');
    raw_angleX = data.('angle_x');
    raw_angleY = data.('angle_y');
    raw_angleZ = data.('angle_z');
    
    raw_targetVelZ = data.('target_vel_z');
    raw_velZ = data.('vel_z');
    
    raw_targetPosZ = data.('target_pos_z');
    raw_posZ = data.('pos_z');
catch
    % 如果列名匹配失败，依据您提供的CSV表头顺序使用列索引提取
    raw_time = data{:, 1};
    
    % 角速度 (Gyro)
    raw_targetGyroX = data{:, 2};
    raw_targetGyroY = data{:, 3};
    raw_targetGyroZ = data{:, 4};
    raw_gyroX = data{:, 5};
    raw_gyroY = data{:, 6};
    raw_gyroZ = data{:, 7};
    
    % 姿态角 (Angle)
    raw_targetAngleX = data{:, 8};
    raw_targetAngleY = data{:, 9};
    raw_targetAngleZ = data{:, 10};
    raw_angleX = data{:, 11};
    raw_angleY = data{:, 12};
    raw_angleZ = data{:, 13};
    
    % Z轴速度
    raw_targetVelZ = data{:, 14};
    raw_velZ = data{:, 15};
    
    % Z轴位置
    raw_targetPosZ = data{:, 16};
    raw_posZ = data{:, 17};
    
    K_cv = data{:, 25};
end

% 时间归零
time = raw_time - raw_time(1);

% 变量赋值打包
target_gyros = [raw_targetGyroX, raw_targetGyroY, raw_targetGyroZ];
actual_gyros = [raw_gyroX, raw_gyroY, raw_gyroZ];

target_angles = [raw_targetAngleX, raw_targetAngleY, raw_targetAngleZ];
actual_angles = [raw_angleX, raw_angleY, raw_angleZ];

target_pos_z = raw_targetPosZ;
actual_pos_z = raw_posZ;
target_vel_z = raw_targetVelZ;
actual_vel_z = raw_velZ;

%% --- 绘图 1: 三轴姿态角跟随曲线 ---
angle_names = {'Roll', 'Pitch', 'Yaw'};

fig_angles = figure(1);
set(fig_angles, 'Color', 'w', 'Units', 'centimeters', 'Position', [2, 2, fig_width, fig_height]);

for i = 1:3
    subplot(3, 1, i);
    hold on;

    plot(time, actual_angles(:, i), '-', 'Color', resp_color, 'LineWidth', 0.7); 
    plot(time, target_angles(:, i), '--', 'Color', setpoint_color, 'LineWidth', 1.0);

    ylabel([angle_names{i}, ' (rad)'], 'Interpreter', 'latex', 'FontSize', 9);
    legend('Measured', 'Target', 'Location', 'best', 'Interpreter', 'latex', 'FontSize', 9);
    
    grid on;
    set(gca, 'Layer', 'top', 'Box', 'on', 'TickLabelInterpreter', 'latex');
    
    if i == 3
        xlabel('$t$ (s)', 'Interpreter', 'latex', 'FontSize', 9);
    else
        set(gca, 'XTickLabel', []); 
    end
end

set(fig_angles, 'PaperUnits', 'centimeters', 'PaperSize', [fig_width fig_height], 'PaperPosition', [0 0 fig_width fig_height]);
print(fig_angles, fullfile(output_folder, 'Attitude_Tracking_Combined.pdf'), '-dpdf', '-r300');


%% --- 绘图 2: 三轴角速度(Gyro)跟随曲线 ---
gyro_names = {'Roll Rate', 'Pitch Rate', 'Yaw Rate'};

fig_gyros = figure(2);
set(fig_gyros, 'Color', 'w', 'Units', 'centimeters', 'Position', [4, 3, fig_width, fig_height]);

for i = 1:3
    subplot(3, 1, i);
    hold on;

    plot(time, actual_gyros(:, i), '-', 'Color', resp_color, 'LineWidth', 0.7); 
    plot(time, target_gyros(:, i), '--', 'Color', setpoint_color, 'LineWidth', 1.0);

    ylabel([gyro_names{i}, ' (rad/s)'], 'Interpreter', 'latex', 'FontSize', 9);
    legend('Measured', 'Target', 'Location', 'best', 'Interpreter', 'latex', 'FontSize', 9);
    
    grid on;
    set(gca, 'Layer', 'top', 'Box', 'on', 'TickLabelInterpreter', 'latex');
    
    if i == 3
        xlabel('$t$ (s)', 'Interpreter', 'latex', 'FontSize', 9);
    else
        set(gca, 'XTickLabel', []); 
    end
end

set(fig_gyros, 'PaperUnits', 'centimeters', 'PaperSize', [fig_width fig_height], 'PaperPosition', [0 0 fig_width fig_height]);
print(fig_gyros, fullfile(output_folder, 'Gyro_Tracking_Combined.pdf'), '-dpdf', '-r300');


%% --- 绘图 3: Z 轴位置与速度跟随曲线 ---
fig_z = figure(3);
set(fig_z, 'Color', 'w', 'Units', 'centimeters', 'Position', [6, 4, fig_width, fig_height]);

% --- 子图 1: Z 轴位置 ---
subplot(2, 1, 1);
hold on;
plot(time, actual_pos_z, '-', 'Color', resp_color, 'LineWidth', 0.7); 
plot(time, target_pos_z, '--', 'Color', setpoint_color, 'LineWidth', 1.0);

ylabel('Z Position (m)', 'Interpreter', 'latex');
legend('Measured $Z$', 'Target $Z$', 'Location', 'best', 'Interpreter', 'latex', 'FontSize', 9);
grid on;
set(gca, 'Layer', 'top', 'Box', 'on', 'TickLabelInterpreter', 'latex');
set(gca, 'XTickLabel', []); 

% --- 子图 2: Z 轴速度 ---
subplot(2, 1, 2);
hold on;
plot(time, actual_vel_z, '-', 'Color', resp_color, 'LineWidth', 0.7); 
plot(time, target_vel_z, '--', 'Color', setpoint_color, 'LineWidth', 1.0);

xlabel('$t$ (s)', 'Interpreter', 'latex', 'FontSize', 9);
ylabel('Z Velocity (m/s)', 'Interpreter', 'latex', 'FontSize', 9);
legend('Measured $V_z$', 'Target $V_z$', 'Location', 'best', 'Interpreter', 'latex', 'FontSize', 9);
grid on;
set(gca, 'Layer', 'top', 'Box', 'on', 'TickLabelInterpreter', 'latex');

set(fig_z, 'PaperUnits', 'centimeters', 'PaperSize', [fig_width fig_height], 'PaperPosition', [0 0 fig_width fig_height]);
print(fig_z, fullfile(output_folder, 'Z_Pos_Vel_Combined.pdf'), '-dpdf', '-r300');

% 清理临时文件
if exist(temp_file, 'file'), delete(temp_file); end
fprintf('所有图形已按 16x12cm 尺寸绘制，并导出为 3 个合并的 PDF 文件。\n');


fig_z = figure(4);
plot(time, K_cv);