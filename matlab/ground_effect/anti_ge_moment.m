% 该脚本用于批量处理无人机力矩数据：包含零偏校准与配色方案优化
% 颜色方案参考 test5_2_1_1.m：目标值深灰，测量值紫红
clc;
clear;
close all;

% 1. 全局配置参数
output_folder = 'pdf/anti_ge_moment/';
if ~exist(output_folder, 'dir'), mkdir(output_folder); end

% 配色方案与排版尺寸
resp_color = [0.70, 0.22, 0.40];      % 测量值颜色 (紫红色)
setpoint_color = [0.1, 0.1, 0.1];    % 目标值颜色 (深灰色)
single_line_color = [0.3, 0.45, 0.8]; % 单线条颜色 (蓝色)

font_name = 'Times New Roman';
font_size = 8;
fig_width = 8;  
fig_height = 5;

% 全局样式设置 (移至循环外，只需设置一次)
set(0, 'defaultAxesFontName', font_name);
set(0, 'defaultTextFontName', font_name);
set(0, 'defaultAxesFontSize', font_size);
set(0, 'defaultTextInterpreter', 'latex');
set(0, 'defaultLegendInterpreter', 'latex');

% 2. 定义需要遍历的文件后缀
suffixes = {'50mm', '100mm', '200mm', '400mm'};

%% 3. 循环处理每个文件
for i = 1:length(suffixes)
    current_suffix = suffixes{i};
    file_name = sprintf('ge_moment_data/anti_moment_ge_raw_%s.csv', current_suffix);
    
    fprintf('正在处理文件: %s...\n', file_name);
    
    if ~exist(file_name, 'file')
        warning('找不到文件: %s，跳过此文件。', file_name);
        continue; 
    end
    
    % --- 数据预处理 ---
    raw_text = fileread(file_name);
    lines = splitlines(raw_text);
    lines(cellfun('isempty', lines)) = []; 
    expected_commas = length(strfind(lines{1}, ','));
    valid_idx = cellfun(@(x) length(strfind(x, ',')) == expected_commas, lines);
    clean_lines = lines(valid_idx);

    % 为防止文件冲突，临时文件也加上后缀
    temp_file = sprintf('temp_moment_final_%s.csv', current_suffix);
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

    % --- 零偏校准 ---
    calib_mask = (raw_time == 0);
    zero_offset_z = mean(raw_moment_z(calib_mask));
    if isnan(zero_offset_z), zero_offset_z = 0; end

    test_idx = raw_time > 0;
    time = raw_time(test_idx);
    calibrated_moment_z = raw_moment_z(test_idx) - zero_offset_z;
    target_moment = raw_target_moment(test_idx);
    motor_angle = raw_motor_angle(test_idx);

    delete(temp_file);

    %% --- 4. 绘图与输出 ---
    
    % 计算动态 Figure 编号，保证独立窗口
    fig1_num = i * 2 - 1;
    fig2_num = i * 2;

    % --- Figure 1: Moment Tracking ---
    fig1 = figure(fig1_num);
    % 稍微错开窗口位置，避免完全重叠
    pos_x1 = 5 + (i-1)*2; 
    set(fig1, 'Color', 'w', 'Units', 'centimeters', 'Position', [pos_x1, 5, fig_width, fig_height]);
    set(fig1, 'Name', sprintf('Moment Tracking - %s', current_suffix));
    hold on;

    plot(time, calibrated_moment_z, '-', 'Color', resp_color, 'LineWidth', 0.7); 
    plot(time, target_moment, '--', 'Color', setpoint_color, 'LineWidth', 1.0);

    xlabel('Time (s)');
    ylabel('Moment (N$\cdot$m)');
    legend('Measured $M_z$', 'Target $M_z$', 'Location', 'best');
    grid on;
    set(gca, 'Layer', 'top', 'Box', 'on');

    set(fig1, 'PaperUnits', 'centimeters', 'PaperSize', [fig_width fig_height], 'PaperPosition', [0 0 fig_width fig_height]);
    
    % 动态生成 PDF 保存路径
    pdf_name_1 = fullfile(output_folder, sprintf('Moment_Tracking_%s.pdf', current_suffix));
    print(fig1, pdf_name_1, '-dpdf', '-r300');

    % --- Figure 2: Motor Angle ---
    fig2 = figure(fig2_num);
    pos_x2 = 14 + (i-1)*2;
    set(fig2, 'Color', 'w', 'Units', 'centimeters', 'Position', [pos_x2, 5, fig_width, fig_height]);
    set(fig2, 'Name', sprintf('Motor Angle - %s', current_suffix));
    hold on;

    plot(time, motor_angle, 'Color', single_line_color, 'LineWidth', 0.8);

    xlabel('Time (s)');
    ylabel('Motor Angle (rad)');
    grid on;
    set(gca, 'Layer', 'top', 'Box', 'on');

    set(fig2, 'PaperUnits', 'centimeters', 'PaperSize', [fig_width fig_height], 'PaperPosition', [0 0 fig_width fig_height]);
    
    % 动态生成 PDF 保存路径
    pdf_name_2 = fullfile(output_folder, sprintf('Motor_Angle_%s.pdf', current_suffix));
    print(fig2, pdf_name_2, '-dpdf', '-r300');
    
end

fprintf('\n所有文件批量处理与图表配色更新完成！共生成 %d 个 PDF 文件。\n已保存至: %s\n', length(suffixes)*2, output_folder);