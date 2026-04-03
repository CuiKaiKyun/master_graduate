%% Drone Flight Data Visualization
clear; clc; close all;

% --- 参数配置 ---
subfix = {'', '_cmp'};
output_folder = './pdf/anti_ge_height/'; 
fig_width = 15;       % 图像宽度 (cm)
fig_height = 5;      % 图像高度 (cm)

% 颜色定义
resp_color = [0, 0.4470, 0.7410];      % 蓝色 (实测值)
setpoint_color = [0.8500, 0.3250, 0.0980]; % 橙红 (目标值)

%% 1. 数据处理
for j = 1:1:length(subfix)
    file_name = sprintf('ge_flight_height_data/flight_data_anti_height%s.csv', subfix{j});
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

        raw_targetVelZ = data.('target_vel_z');
        raw_velZ = data.('vel_z');

        raw_targetPosZ = data.('target_pos_z');
        raw_posZ = data.('pos_z');
    catch
        % 如果列名匹配失败，依据您提供的CSV表头顺序使用列索引提取
        raw_time = data{:, 1};

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

    target_pos_z = raw_targetPosZ;
    actual_pos_z = raw_posZ;
    target_vel_z = raw_targetVelZ;
    actual_vel_z = raw_velZ;

    %% --- 绘图 1: 高度跟随曲线 ---
    fig = figure;
    hold on;

    fig.Units = 'centimeters';
    figPos = [1, 1, 15, 6]; 
    fig.Position = figPos;  

    set(gcf, 'Units', 'centimeters');
    set(gcf, 'PaperUnits', 'centimeters'); 
    set(gcf, 'PaperPosition', [0, 0, figPos(3), figPos(4)]);
    set(gcf, 'PaperSize', [figPos(3), figPos(4)]); 

    plot(time, actual_pos_z, '-', 'Color', resp_color, 'LineWidth', 0.8); 
    plot(time, target_pos_z, '--', 'Color', setpoint_color, 'LineWidth', 0.8);

    ylabel('$p_z^e$ (m)', 'Interpreter', 'latex', 'FontSize', 9);
    xlabel('$t$ (s)', 'Interpreter', 'latex', 'FontSize', 9);
    legend('测量值', '期望值', 'Location', 'best', 'Interpreter', 'tex', 'FontName', 'SimSun', 'FontSize', 9);

    ylim([-0.8, 0]);
    xlim([min(time), max(time)*1.05]);
    
    grid on;
    set(gca, 'Layer', 'top', 'Box', 'on', 'TickLabelInterpreter', 'latex');
    
    pdf_path = sprintf('%santi_ge_height%s_pos', output_folder, subfix{j});
    print(gcf, '-dpdf', '-r300', pdf_path);

    %% --- 绘图 2: 三轴角速度(Gyro)跟随曲线 ---

    fig = figure;
    hold on;

    fig.Units = 'centimeters';
    figPos = [1, 1, 15, 6]; 
    fig.Position = figPos;  

    set(gcf, 'Units', 'centimeters');
    set(gcf, 'PaperUnits', 'centimeters'); 
    set(gcf, 'PaperPosition', [0, 0, figPos(3), figPos(4)]);
    set(gcf, 'PaperSize', [figPos(3), figPos(4)]); 

    plot(time, actual_vel_z, '-', 'Color', resp_color, 'LineWidth', 0.8); 
    plot(time, target_vel_z, '--', 'Color', setpoint_color, 'LineWidth', 0.8);

    ylabel('$v_z^e$ (m/s)', 'Interpreter', 'latex', 'FontSize', 9);
    legend('测量值', '期望值', 'Location', 'best', 'Interpreter', 'tex', 'FontName', 'SimSun', 'FontSize', 9);

    xlim([min(time), max(time)*1.05]);

    grid on;
    set(gca, 'Layer', 'top', 'Box', 'on', 'TickLabelInterpreter', 'latex');

    xlabel('$t$ (s)', 'Interpreter', 'latex', 'FontSize', 9);
    pdf_path = sprintf('%santi_ge_height%s_vel', output_folder, subfix{j});
    print(gcf, '-dpdf', '-r300', pdf_path);

end
