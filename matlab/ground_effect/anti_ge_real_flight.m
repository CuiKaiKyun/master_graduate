%% Drone Flight Data Visualization
clear; clc; close all;

% --- 参数配置 ---
file_name = 'ge_flight_data/flight_data.csv'; % 请确保路径正确
output_folder = './'; 
fig_width = 12;       % 图像宽度 (cm)
fig_height = 8;       % 图像高度 (cm)

% 颜色定义
resp_color = [0, 0.4470, 0.7410];     % 蓝色 (实测值)
setpoint_color = [0.8500, 0.3250, 0.0980]; % 橙红 (目标值)

%% 2. 数据处理
if ~exist(file_name, 'file'), error('找不到文件: %s', file_name); end
raw_text = fileread(file_name);
lines = splitlines(raw_text);
lines(cellfun('isempty', lines)) = []; 

% 这里的逻辑保持与您一致，如果是制表符请将 ',' 改为 '\t'
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
    raw_time = data.('time_s_');
    raw_targetAngleX = data.('targetAngleX');
    raw_targetAngleY = data.('targetAngleY');
    raw_targetAngleZ = data.('targetAngleZ');
    raw_angleX = data.('angleX');
    raw_angleY = data.('angleY');
    raw_angleZ = data.('angleZ');
    % 新增速度变量提取
    raw_targetVelZ = data.('targetVelZ');
    raw_velZ = data.('velZ');
    
    raw_targetPosZ = data.('targetPosZ');
    raw_posZ = data.('posZ');
catch
    % 根据 real_flight.csv 的列顺序：
    % 1:time, 8-10:target angle, 11-13:angle, 14:target vel z, 15:vel z, 16:target pos z, 17:pos z
    raw_time = data{:, 1};
    raw_targetAngleX = data{:, 8};
    raw_targetAngleY = data{:, 9};
    raw_targetAngleZ = data{:, 10};
    raw_angleX = data{:, 11};
    raw_angleY = data{:, 12};
    raw_angleZ = data{:, 13};
    
    % --- 新增：提取第 14 和 15 列作为速度数据 ---
    raw_targetVelZ = data{:, 14};
    raw_velZ = data{:, 15};
    
    raw_targetPosZ = data{:, 16};
    raw_posZ = data{:, 17};
end

% 时间归零
time = raw_time - raw_time(1);

% 变量赋值
target_angles = [raw_targetAngleX, raw_targetAngleY, raw_targetAngleZ];
actual_angles = [raw_angleX, raw_angleY, raw_angleZ];
target_pos_z = raw_targetPosZ;
actual_pos_z = raw_posZ;
% 新增速度变量
target_vel_z = raw_targetVelZ;
actual_vel_z = raw_velZ;

%% --- 绘图 1: 三轴姿态角跟随曲线 ---
angle_names = {'Roll', 'Pitch', 'Yaw'};
file_names = {'Roll_Tracking', 'Pitch_Tracking', 'Yaw_Tracking'};

for i = 1:3
    fig = figure(i);
    set(fig, 'Color', 'w', 'Units', 'centimeters', 'Position', [2, 2, fig_width, fig_height]);
    hold on;

    plot(time, actual_angles(:, i), '-', 'Color', resp_color, 'LineWidth', 0.7); 
    plot(time, target_angles(:, i), '--', 'Color', setpoint_color, 'LineWidth', 1.0);

    xlabel('Time (s)', 'Interpreter', 'latex');
    ylabel([angle_names{i}, ' Angle (rad)'], 'Interpreter', 'latex');
    legend(['Measured ', angle_names{i}], ['Target ', angle_names{i}], ...
           'Location', 'best', 'Interpreter', 'latex');
    
    grid on;
    set(gca, 'Layer', 'top', 'Box', 'on', 'TickLabelInterpreter', 'latex');
    set(fig, 'PaperUnits', 'centimeters', 'PaperSize', [fig_width fig_height], 'PaperPosition', [0 0 fig_width fig_height]);
    print(fig, [output_folder, file_names{i}, '.pdf'], '-dpdf', '-r300');
end

%% --- 绘图 2: Z 轴位置跟随曲线 (Figure 4) ---
fig_z_pos = figure(4);
set(fig_z_pos, 'Color', 'w', 'Units', 'centimeters', 'Position', [5, 5, fig_width, fig_height]);
hold on;

plot(time, actual_pos_z, '-', 'Color', resp_color, 'LineWidth', 0.7); 
plot(time, target_pos_z, '--', 'Color', setpoint_color, 'LineWidth', 1.0);

xlabel('Time (s)', 'Interpreter', 'latex');
ylabel('Z Position (m)', 'Interpreter', 'latex');
legend('Measured $Z$ Pos', 'Target $Z$ Pos', 'Location', 'best', 'Interpreter', 'latex');

grid on;
set(gca, 'Layer', 'top', 'Box', 'on', 'TickLabelInterpreter', 'latex');
set(fig_z_pos, 'PaperUnits', 'centimeters', 'PaperSize', [fig_width fig_height], 'PaperPosition', [0 0 fig_width fig_height]);
print(fig_z_pos, [output_folder, 'Z_Position_Tracking.pdf'], '-dpdf', '-r300');

%% --- 新增绘图 3: Z 轴速度跟随曲线 (Figure 5) ---
fig_z_vel = figure(5);
set(fig_z_vel, 'Color', 'w', 'Units', 'centimeters', 'Position', [8, 8, fig_width, fig_height]);
hold on;

% 按照要求：先画测量值(实线)，后画目标值(虚线)
plot(time, actual_vel_z, '-', 'Color', resp_color, 'LineWidth', 0.7); 
plot(time, target_vel_z, '--', 'Color', setpoint_color, 'LineWidth', 1.0);

xlabel('Time (s)', 'Interpreter', 'latex');
ylabel('Z Velocity (m/s)', 'Interpreter', 'latex');
legend('Measured $V_z$', 'Target $V_z$', 'Location', 'best', 'Interpreter', 'latex');

grid on;
set(gca, 'Layer', 'top', 'Box', 'on', 'TickLabelInterpreter', 'latex');

% 导出 PDF
set(fig_z_vel, 'PaperUnits', 'centimeters', 'PaperSize', [fig_width fig_height], 'PaperPosition', [0 0 fig_width fig_height]);
print(fig_z_vel, [output_folder, 'Z_Velocity_Tracking.pdf'], '-dpdf', '-r300');

% 删除临时文件
if exist(temp_file, 'file'), delete(temp_file); end
fprintf('所有图形（含速度曲线）已绘制并导出为 PDF 文件。\n');