% 该脚本用于处理无人机推力数据：包含零偏校准、转速/推力跟随及电压分析
% 绘图标准：8cm x 5cm, Times New Roman, LaTeX Interpreter, PDF export via 'print'
% 颜色方案参考 test5_2_1_1.m
% 输出路径：pdf/anti_ge_thrust/

clc;
clear;
close all;

% 1. 配置参数
file_name = 'ge_thrust_data/anti_thrust_ge_raw_50mm_3.csv'; 
output_folder = 'pdf/anti_ge_thrust/'; % 指定输出文件夹

% 如果文件夹不存在则创建
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

% 提取自 test5_2_1_1.m 的配色方案
resp_color = [0.70, 0.22, 0.40];      % 测量值颜色 (紫红色)
setpoint_color = [0.1, 0.1, 0.1];    % 目标值颜色 (深灰色)
single_line_color = [0.3, 0.45, 0.8]; % 单线条颜色 (蓝色)

font_name = 'Times New Roman';
font_size = 8;
fig_width = 8;  % 宽 8cm
fig_height = 5; % 高 5cm

%% 2. 数据预处理（自动清理丢包数据）
if ~exist(file_name, 'file')
    error('找不到文件: %s', file_name);
end

raw_text = fileread(file_name);
lines = splitlines(raw_text);
lines(cellfun('isempty', lines)) = []; 

expected_commas = length(strfind(lines{1}, ','));
valid_idx = cellfun(@(x) length(strfind(x, ',')) == expected_commas, lines);
clean_lines = lines(valid_idx);

temp_file = 'temp_thrust_data_v2.csv';
fid = fopen(temp_file, 'w');
fprintf(fid, '%s\n', clean_lines{:});
fclose(fid);

%% 3. 读取与解析数据
opts = detectImportOptions(temp_file);
data = readtable(temp_file, opts);

% 提取原始列数据
raw_time          = data.('time_s_');
raw_force_z       = data.('force_z_N_');
raw_target_thrust = data.('target_thrust_N_');
desire_speed      = data.('desire_rotor_speed_m_s_');
actual_speed      = data.('rotor_speed_m_s_');
battery_vol       = data.('battery_vol_V_');

%% 4. 零偏计算与数据补偿
calib_mask = (raw_time == 0);
if any(calib_mask)
    zero_offset_z = mean(raw_force_z(calib_mask));
    fprintf('Force_Z 零偏校准值: %.4f N\n', zero_offset_z);
else
    zero_offset_z = 0;
end

% 提取正式测试数据 (time > 0)
test_idx = (raw_time > 0);
time = raw_time(test_idx);
calibrated_thrust = -(raw_force_z(test_idx) - zero_offset_z);
target_thrust     = raw_target_thrust(test_idx);
plot_desire_speed = desire_speed(test_idx);
plot_actual_speed = actual_speed(test_idx);
plot_battery_vol  = battery_vol(test_idx);

delete(temp_file);

%% 5. 全局绘图样式设置 (参照 test5_2_1_1)
set(0, 'defaultAxesFontName', font_name);
set(0, 'defaultTextFontName', font_name);
set(0, 'defaultAxesFontSize', font_size);
set(0, 'defaultTextInterpreter', 'latex');
set(0, 'defaultLegendInterpreter', 'latex');

%% 6. 绘图与输出

% --- Figure 1: Speed Tracking ---
fig1 = figure(1);
set(fig1, 'Color', 'w', 'Units', 'centimeters', 'Position', [2, 10, fig_width, fig_height]);
hold on;
% 先画实际值(实线)，再画期望值(深灰虚线)
plot(time, plot_actual_speed, '-', 'Color', resp_color, 'LineWidth', 0.7); 
plot(time, plot_desire_speed, '--', 'Color', setpoint_color, 'LineWidth', 1.0);

ylabel('Rotor Speed (m/s)');
xlabel('Time (s)');
legend('Actual Speed', 'Desire Speed', 'Location', 'best');
grid on;
set(gca, 'Layer', 'top', 'Box', 'on');

% 导出PDF
set(fig1, 'PaperUnits', 'centimeters', 'PaperSize', [fig_width fig_height], 'PaperPosition', [0 0 fig_width fig_height]);
print(fig1, [output_folder, 'Plot_Speed_Tracking.pdf'], '-dpdf', '-r300');


% --- Figure 2: Thrust Tracking ---
fig2 = figure(2);
set(fig2, 'Color', 'w', 'Units', 'centimeters', 'Position', [11, 10, fig_width, fig_height]);
hold on;
% 先画实测推力(实线)，再画目标推力(深灰虚线)
plot(time, calibrated_thrust, '-', 'Color', resp_color, 'LineWidth', 0.7); 
plot(time, target_thrust, '--', 'Color', setpoint_color, 'LineWidth', 1.0);

ylabel('Thrust (N)');
xlabel('Time (s)');
legend('Measured Thrust', 'Target Thrust', 'Location', 'best');
grid on;
set(gca, 'Layer', 'top', 'Box', 'on');

% 导出PDF
set(fig2, 'PaperUnits', 'centimeters', 'PaperSize', [fig_width fig_height], 'PaperPosition', [0 0 fig_width fig_height]);
print(fig2, [output_folder, 'Plot_Thrust_Tracking.pdf'], '-dpdf', '-r300');


% --- Figure 3: Battery Voltage ---
fig3 = figure(3);
set(fig3, 'Color', 'w', 'Units', 'centimeters', 'Position', [20, 10, fig_width, fig_height]);
% 使用参考文件中的蓝色
plot(time, plot_battery_vol, 'Color', single_line_color, 'LineWidth', 0.8); 

ylabel('Battery Voltage (V)');
xlabel('Time (s)');
grid on;
set(gca, 'Layer', 'top', 'Box', 'on');

% 导出PDF
set(fig3, 'PaperUnits', 'centimeters', 'PaperSize', [fig_width fig_height], 'PaperPosition', [0 0 fig_width fig_height]);
print(fig3, [output_folder, 'Plot_Battery_Voltage.pdf'], '-dpdf', '-r300');

fprintf('推力图表配色更新完成。PDF已保存至: %s\n', output_folder);