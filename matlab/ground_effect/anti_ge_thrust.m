% 该脚本用于循环处理无人机推力数据并应用多套学术配色方案
% 绘图标准：8cm x 5cm, Times New Roman, LaTeX Interpreter
% 输出路径：pdf/anti_ge_thrust/

clc;
clear;
close all;

% 1. 配置参数与路径
base_path = 'ge_thrust_data/'; 
output_folder = 'pdf/anti_ge_thrust/'; 
suffixes = {'50mm'};

% --- 定义三组不同的学术配色 ---
% Plot 1 (Speed): 经典蓝-橙
color1_actual = [0, 0.4470, 0.7410];  % 蓝色
color1_desire = [0.8500, 0.3250, 0.0980]; % 橙红
color1_cmp_actual = [0.9290, 0.6940, 0.1250];  % 蓝色
color1_cmp_desire = [0.4940, 0.1840, 0.5560]; % 橙红

% Plot 2 (Thrust): 森林绿-深灰
color2_cmp_actual   = [0.4940, 0.1840, 0.5560]; % 紫色
color2_actual = [0.4660, 0.6740, 0.1880]; % 绿色
color2_target = [0.15, 0.15, 0.15];       % 深灰色

% Plot 3 (Voltage): 深紫
color3_line   = [0.4940, 0.1840, 0.5560]; % 紫色

font_name = 'Times New Roman';
font_size = 8;
fig_width = 8;  
fig_height = 5;

if ~exist(output_folder, 'dir'), mkdir(output_folder); end

% 全局绘图样式设置
set(0, 'defaultAxesFontName', font_name);
set(0, 'defaultTextFontName', font_name);
set(0, 'defaultAxesFontSize', font_size);
set(0, 'defaultTextInterpreter', 'latex');
set(0, 'defaultLegendInterpreter', 'latex');

%% 2. 循环处理每个文件
for i = 1:length(suffixes)
    cur_suffix = suffixes{i};
    file_name = [base_path, 'anti_thrust_ge_raw_', cur_suffix, '.csv'];
    cmp_file_name = [base_path, 'anti_thrust_ge_raw_', cur_suffix, '_cmp.csv'];
    
    fprintf('正在处理文件: %s ...\n', file_name);
    if ~exist(file_name, 'file'), continue; end
    if ~exist(cmp_file_name, 'file'), continue; end

    %% 3. 数据预处理
    raw_text = fileread(file_name);
    lines = splitlines(raw_text);
    lines(cellfun('isempty', lines)) = []; 
    expected_commas = length(strfind(lines{1}, ','));
    valid_idx = cellfun(@(x) length(strfind(x, ',')) == expected_commas, lines);
    clean_lines = lines(valid_idx);

    temp_file = ['temp_thrust_', cur_suffix, '.csv'];
    fid = fopen(temp_file, 'w');
    fprintf(fid, '%s\n', clean_lines{:});
    fclose(fid);
    
    raw_text = fileread(cmp_file_name);
    lines = splitlines(raw_text);
    lines(cellfun('isempty', lines)) = []; 
    expected_commas = length(strfind(lines{1}, ','));
    valid_idx = cellfun(@(x) length(strfind(x, ',')) == expected_commas, lines);
    clean_lines = lines(valid_idx);

    temp_cmp_file = ['temp_thrust_', cur_suffix, '_cmp.csv'];
    fid = fopen(temp_cmp_file, 'w');
    fprintf(fid, '%s\n', clean_lines{:});
    fclose(fid);

    %% 4. 读取与解析数据
    opts = detectImportOptions(temp_file);
    data = readtable(temp_file, opts);

    raw_time          = data.('time_s_');
    raw_force_z       = data.('force_z_N_');
    raw_target_thrust = data.('target_thrust_N_');
    desire_speed      = data.('desire_rotor_speed_m_s_');
    actual_speed      = data.('rotor_speed_m_s_');
    battery_vol       = data.('battery_vol_V_');

    % 零偏补偿
    calib_mask = (raw_time == 0);
    zero_offset_z = 0;
    if any(calib_mask), zero_offset_z = mean(raw_force_z(calib_mask)); end

    test_idx = (raw_time > 0);
    time = raw_time(test_idx);
    calibrated_thrust = -(raw_force_z(test_idx) - zero_offset_z);
    target_thrust     = raw_target_thrust(test_idx);
    plot_desire_speed = desire_speed(test_idx);
    plot_actual_speed = actual_speed(test_idx);
    plot_battery_vol  = battery_vol(test_idx);

    delete(temp_file);
    
    opts = detectImportOptions(temp_cmp_file);
    data = readtable(temp_cmp_file, opts);

    raw_cmp_time = data.('time_s_');
    raw_cmp_force_z = data.('force_z_N_');
    desire_cmp_speed = data.('desire_rotor_speed_m_s_');
    actual_cmp_speed = data.('rotor_speed_m_s_');

    % 零偏补偿
    calib_mask = (raw_cmp_time == 0);
    zero_offset_z = 0;
    if any(calib_mask), zero_offset_z = mean(raw_cmp_force_z(calib_mask)); end

    test_idx = (raw_cmp_time > 0);
    cmp_time = raw_cmp_time(test_idx);
    calibrated_cmp_thrust = -(raw_cmp_force_z(test_idx) - zero_offset_z);
    plot_desire_cmp_speed = desire_cmp_speed(test_idx);
    plot_actual_cmp_speed = actual_cmp_speed(test_idx);

    delete(temp_cmp_file);

    %% 5. 绘图与输出 (应用区分配色)
    
    % --- Figure 1: Speed Tracking (蓝-橙系) ---
    fig1 = figure(1); clf;
    set(fig1, 'Color', 'w', 'Units', 'centimeters', 'Position', [2, 10, fig_width, fig_height]);
    hold on;
    plot(cmp_time, plot_actual_cmp_speed, '-', 'Color', color1_cmp_actual, 'LineWidth', 0.8); 
    plot(time, plot_actual_speed, '-', 'Color', color1_actual, 'LineWidth', 0.8); 
    plot(cmp_time, plot_desire_cmp_speed, ':', 'Color', color1_cmp_desire, 'LineWidth', 1.2);
    plot(time, plot_desire_speed, ':', 'Color', color1_desire, 'LineWidth', 1.2);
    ylabel('$\Omega$ (rad/s)', 'FontSize', 9);
    xlabel('$t$ (s)', 'FontSize', 9);
    lgd = legend('$\Omega^{\prime}$', '$\Omega$', '$\Omega_{d}^{\prime}$', '$\Omega_{d}$', 'Location', 'southeast');
    set(lgd, 'Interpreter', 'latex', 'FontName', 'SimSun', 'FontSize', 9);
    grid on; set(gca, 'Layer', 'top', 'Box', 'on');
    
    % 边距优化
    y_data = [plot_actual_speed; plot_desire_speed; plot_actual_cmp_speed; plot_desire_cmp_speed];
    y_range = max(y_data) - min(y_data);
    if y_range == 0, y_range = 1; end
    ylim([min(y_data) - 0.15*y_range, max(y_data) + 0.15*y_range]);
    xlim([min(time) - 0.02*(max(time)-min(time)), max(time) + 0.02*(max(time)-min(time))]);
    
    set(fig1, 'PaperUnits', 'centimeters', 'PaperSize', [fig_width fig_height], 'PaperPosition', [0 0 fig_width fig_height]);
    print(fig1, [output_folder, 'Plot_Speed_Tracking_', cur_suffix, '.pdf'], '-dpdf', '-r300');

    % --- Figure 2: Thrust Tracking (绿-灰系) ---
    fig2 = figure(2); clf;
    set(fig2, 'Color', 'w', 'Units', 'centimeters', 'Position', [11, 10, fig_width, fig_height]);
    hold on;
    plot(cmp_time, calibrated_cmp_thrust, '-', 'Color', color2_cmp_actual, 'LineWidth', 0.8);
    plot(time, calibrated_thrust, '-', 'Color', color2_actual, 'LineWidth', 0.8); 
    plot(time, target_thrust, ':', 'Color', color2_target, 'LineWidth', 1.2);
    ylabel('$T$ (N)', 'FontSize', 9);
    xlabel('$t$ (s)', 'FontSize', 9);
    lgd = legend('$T^{\prime}$', '$T$', '$T_{d}$', 'Location', 'southeast');
    set(lgd, 'Interpreter', 'latex', 'FontName', 'SimSun', 'FontSize', 9);
    grid on; set(gca, 'Layer', 'top', 'Box', 'on');
    
    % 边距优化
    y_data = [calibrated_thrust; target_thrust; calibrated_cmp_thrust];
    y_range = max(y_data) - min(y_data);
    if y_range == 0, y_range = 1; end
    ylim([min(y_data) - 0.15*y_range, max(y_data) + 0.15*y_range]);
    xlim([min(time) - 0.02*(max(time)-min(time)), max(time) + 0.02*(max(time)-min(time))]);
    
    set(fig2, 'PaperUnits', 'centimeters', 'PaperSize', [fig_width fig_height], 'PaperPosition', [0 0 fig_width fig_height]);
    print(fig2, [output_folder, 'Plot_Thrust_Tracking_', cur_suffix, '.pdf'], '-dpdf', '-r300');

    % --- Figure 3: Battery Voltage (紫系) ---
%     fig3 = figure(3); clf;
%     set(fig3, 'Color', 'w', 'Units', 'centimeters', 'Position', [20, 10, fig_width, fig_height]);
%     plot(time, plot_battery_vol, 'Color', color3_line, 'LineWidth', 0.8); 
%     ylabel('$V_{bat}$ (V)');
%     xlabel('$t$ (s)');
%     grid on; set(gca, 'Layer', 'top', 'Box', 'on');
%     
%     % 边距优化
%     y_data = [plot_battery_vol];
%     y_range = max(y_data) - min(y_data);
%     if y_range == 0, y_range = 1; end
%     ylim([min(y_data) - 0.15*y_range, max(y_data) + 0.15*y_range]);
%     xlim([min(time) - 0.02*(max(time)-min(time)), max(time) + 0.02*(max(time)-min(time))]);
%     print(fig3, [output_folder, 'Plot_Voltage_', cur_suffix, '.pdf'], '-dpdf', '-r300');
%     
%     set(fig3, 'PaperUnits', 'centimeters', 'PaperSize', [fig_width fig_height], 'PaperPosition', [0 0 fig_width fig_height]);
%     print(fig3, [output_folder, 'Plot_Battery_Voltage_', cur_suffix, '.pdf'], '-dpdf', '-r300');

end

fprintf('\n所有规格文件处理完成，PDF已应用区分配色并保存至: %s\n', output_folder);