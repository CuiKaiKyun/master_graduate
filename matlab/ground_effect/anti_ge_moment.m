% 该脚本用于处理无人机力矩数据：包含零偏校准与配色方案优化
% 颜色方案参考 test5_2_1_1.m：目标值深灰，测量值紫红
clc;
clear;
close all;

% 1. 配置参数
file_name = 'ge_moment_data/anti_moment_ge_raw_50mm_1.csv'; 
output_folder = 'pdf/anti_ge_moment/';

if ~exist(output_folder, 'dir'), mkdir(output_folder); end

% 提取自 test5_2_1_1.m 的配色方案
resp_color = [0.70, 0.22, 0.40];      % 测量值颜色 (紫红色)
setpoint_color = [0.1, 0.1, 0.1];    % 目标值颜色 (深灰色)
single_line_color = [0.3, 0.45, 0.8]; % 单线条颜色 (蓝色)

font_name = 'Times New Roman';
font_size = 8;
fig_width = 8;  
fig_height = 5;

%% 2. 数据处理 (略，保持与之前一致)
if ~exist(file_name, 'file'), error('找不到文件: %s', file_name); end
raw_text = fileread(file_name);
lines = splitlines(raw_text);
lines(cellfun('isempty', lines)) = []; 
expected_commas = length(strfind(lines{1}, ','));
valid_idx = cellfun(@(x) length(strfind(x, ',')) == expected_commas, lines);
clean_lines = lines(valid_idx);

temp_file = 'temp_moment_final.csv';
fid = fopen(temp_file, 'w');
fprintf(fid, '%s\n', clean_lines{:});
fclose(fid);

opts = detectImportOptions(temp_file);
data = readtable(temp_file, opts);

try
    raw_time = data.('time_s_');
    raw_moment_z = data.('moment_z_N_m_');
    raw_target_moment = data.('target_moment_N_m_');
    raw_motor_angle = data.('motor_angle_1_rad_');
catch
    raw_time = data{:, 1}; raw_moment_z = data{:, 4};
    raw_target_moment = data{:, 9}; raw_motor_angle = data{:, 10};
end

calib_mask = (raw_time == 0);
zero_offset_z = mean(raw_moment_z(calib_mask));
if isnan(zero_offset_z), zero_offset_z = 0; end

test_idx = raw_time > 0;
time = raw_time(test_idx);
calibrated_moment_z = raw_moment_z(test_idx) - zero_offset_z;
target_moment = raw_target_moment(test_idx);
motor_angle = raw_motor_angle(test_idx);

delete(temp_file);

%% 3. 全局样式设置
set(0, 'defaultAxesFontName', font_name);
set(0, 'defaultTextFontName', font_name);
set(0, 'defaultAxesFontSize', font_size);
set(0, 'defaultTextInterpreter', 'latex');
set(0, 'defaultLegendInterpreter', 'latex');

%% 4. 绘图与输出

% --- Figure 1: Moment Tracking ---
fig1 = figure(1);
set(fig1, 'Color', 'w', 'Units', 'centimeters', 'Position', [5, 5, fig_width, fig_height]);
hold on;

% 按照你的要求：先画测量值(实线)，后画目标值(虚线)
plot(time, calibrated_moment_z, '-', 'Color', resp_color, 'LineWidth', 0.7); 
plot(time, target_moment, '--', 'Color', setpoint_color, 'LineWidth', 1.0);

xlabel('Time (s)');
ylabel('Moment (N$\cdot$m)');
legend('Measured $M_z$', 'Target $M_z$', 'Location', 'best');
grid on;
set(gca, 'Layer', 'top', 'Box', 'on');

set(fig1, 'PaperUnits', 'centimeters', 'PaperSize', [fig_width fig_height], 'PaperPosition', [0 0 fig_width fig_height]);
print(fig1, [output_folder, 'Moment_Tracking.pdf'], '-dpdf', '-r300');


% --- Figure 2: Motor Angle ---
fig2 = figure(2);
set(fig2, 'Color', 'w', 'Units', 'centimeters', 'Position', [14, 5, fig_width, fig_height]);

% 单线条使用参考文件中的蓝色
plot(time, motor_angle, 'Color', single_line_color, 'LineWidth', 0.8);

xlabel('Time (s)');
ylabel('Motor Angle (rad)');
grid on;
set(gca, 'Layer', 'top', 'Box', 'on');

set(fig2, 'PaperUnits', 'centimeters', 'PaperSize', [fig_width fig_height], 'PaperPosition', [0 0 fig_width fig_height]);
print(fig2, [output_folder, 'Motor_Angle.pdf'], '-dpdf', '-r300');

fprintf('力矩图表配色更新完成。已保存至: %s\n', output_folder);