%% Drone Flight Data Visualization
clear; clc; close all;

% --- 参数配置 ---
file_name = 'ge_flight_data/flight_data.csv'; % 请确保路径正确
output_folder = './'; 
fig_width = 16;       % 图像宽度 (cm) - 已更新
fig_height = 12;      % 图像高度 (cm) - 已更新

% 颜色定义
resp_color = [0, 0.4470, 0.7410];      % 蓝色 (实测值)
setpoint_color = [0.8500, 0.3250, 0.0980]; % 橙红 (目标值)

%% 1. 数据处理
if ~exist(file_name, 'file'), error('找不到文件: %s', file_name); end
raw_text = fileread(file_name);
lines = splitlines(raw_text);
lines(cellfun('isempty', lines)) = []; 

% 如果是制表符请将 ',' 改为 '\t'
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
    
    raw_targetVelZ = data.('targetVelZ');
    raw_velZ = data.('velZ');
    
    raw_targetPosZ = data.('targetPosZ');
    raw_posZ = data.('posZ');
catch
    % 根据 real_flight.csv 的列顺序
    raw_time = data{:, 1};
    raw_targetAngleX = data{:, 8};
    raw_targetAngleY = data{:, 9};
    raw_targetAngleZ = data{:, 10};
    raw_angleX = data{:, 11};
    raw_angleY = data{:, 12};
    raw_angleZ = data{:, 13};
    
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
target_vel_z = raw_targetVelZ;
actual_vel_z = raw_velZ;

%% --- 绘图 1: 三轴姿态角跟随曲线 ---
angle_names = {'Roll', 'Pitch', 'Yaw'};

fig_angles = figure(1);
% 应用新的窗口尺寸
set(fig_angles, 'Color', 'w', 'Units', 'centimeters', 'Position', [2, 2, fig_width, fig_height]);

for i = 1:3
    subplot(3, 1, i);
    hold on;

    plot(time, actual_angles(:, i), '-', 'Color', resp_color, 'LineWidth', 0.7); 
    plot(time, target_angles(:, i), '--', 'Color', setpoint_color, 'LineWidth', 1.0);

    ylabel([angle_names{i}, ' (rad)'], 'Interpreter', 'latex', 'FontSize', 8);
    legend('Measured', 'Target', 'Location', 'best', 'Interpreter', 'latex', 'FontSize', 8);
    
    grid on;
    set(gca, 'Layer', 'top', 'Box', 'on', 'TickLabelInterpreter', 'latex');
    
    % 仅在最底部的子图显示 X 轴标签
    if i == 3
        xlabel('Time (s)', 'Interpreter', 'latex', 'FontSize', 8);
    else
        set(gca, 'XTickLabel', []); 
    end
end

set(fig_angles, 'PaperUnits', 'centimeters', 'PaperSize', [fig_width fig_height], 'PaperPosition', [0 0 fig_width fig_height]);
print(fig_angles, fullfile(output_folder, 'Attitude_Tracking_Combined.pdf'), '-dpdf', '-r300');


%% --- 绘图 2: Z 轴位置与速度跟随曲线 (合并至同一窗口) ---
fig_z = figure(2);
% 应用新的窗口尺寸，并稍微错开显示位置
set(fig_z, 'Color', 'w', 'Units', 'centimeters', 'Position', [4, 4, fig_width, fig_height]);

% --- 子图 1: Z 轴位置 ---
subplot(2, 1, 1);
hold on;
plot(time, actual_pos_z, '-', 'Color', resp_color, 'LineWidth', 0.7); 
plot(time, target_pos_z, '--', 'Color', setpoint_color, 'LineWidth', 1.0);

ylabel('Z Position (m)', 'Interpreter', 'latex');
legend('Measured $Z$', 'Target $Z$', 'Location', 'best', 'Interpreter', 'latex', 'FontSize', 8);
grid on;
set(gca, 'Layer', 'top', 'Box', 'on', 'TickLabelInterpreter', 'latex');
set(gca, 'XTickLabel', []); % 隐藏 X 轴刻度，为了排版美观

% --- 子图 2: Z 轴速度 ---
subplot(2, 1, 2);
hold on;
plot(time, actual_vel_z, '-', 'Color', resp_color, 'LineWidth', 0.7); 
plot(time, target_vel_z, '--', 'Color', setpoint_color, 'LineWidth', 1.0);

xlabel('Time (s)', 'Interpreter', 'latex', 'FontSize', 8);
ylabel('Z Velocity (m/s)', 'Interpreter', 'latex', 'FontSize', 8);
legend('Measured $V_z$', 'Target $V_z$', 'Location', 'best', 'Interpreter', 'latex', 'FontSize', 8);
grid on;
set(gca, 'Layer', 'top', 'Box', 'on', 'TickLabelInterpreter', 'latex');

% 导出合并后的 Z 轴 PDF
set(fig_z, 'PaperUnits', 'centimeters', 'PaperSize', [fig_width fig_height], 'PaperPosition', [0 0 fig_width fig_height]);
print(fig_z, fullfile(output_folder, 'Z_Pos_Vel_Combined.pdf'), '-dpdf', '-r300');

% 清理临时文件
if exist(temp_file, 'file'), delete(temp_file); end
fprintf('所有图形已按 16x12cm 尺寸绘制，并导出为 2 个合并的 PDF 文件。\n');