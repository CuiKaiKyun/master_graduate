%% Drone Flight Data Visualization
clear; clc; close all;

% --- 参数配置 ---
subfix = {'100mm', '100mm_cmp', '200mm', '200mm_cmp'};
output_folder = './pdf/anti_ge_yaw/'; 
fig_width = 15;       % 图像宽度 (cm)
fig_height = 5;      % 图像高度 (cm)

% 颜色定义
resp_color = [0, 0.4470, 0.7410];      % 蓝色 (实测值)
setpoint_color = [0.8500, 0.3250, 0.0980]; % 橙红 (目标值)

%% 1. 数据处理
for j = 1:1:length(subfix)
    file_name = sprintf('ge_flight_yaw_data/flight_data_anti_yaw_%s.csv', subfix{j});
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
    
    % 截取前40秒
    idx = time <= 40;
    time = time(idx);

    % 对所有后续使用的变量进行索引截取
    target_gyros = target_gyros(idx, :);
    actual_gyros = actual_gyros(idx, :);
    target_angles = target_angles(idx, :);
    actual_angles = actual_angles(idx, :);
    target_pos_z = target_pos_z(idx);
    actual_pos_z = actual_pos_z(idx);
    target_vel_z = target_vel_z(idx);
    actual_vel_z = actual_vel_z(idx);
    K_cv = K_cv(idx);

    %% --- 绘图 1: 三轴姿态角跟随曲线 ---
    angle_names = {'$\phi$', '$\theta$', '$\psi$'};
    pdf_name_subfix = {'roll', 'pitch', 'yaw'};

    for i = 1:3
        fig = figure;
        hold on;

        fig.Units = 'centimeters';
        figPos = [1, 1, 15, 5]; 
        fig.Position = figPos;  

        set(gcf, 'Units', 'centimeters');
        set(gcf, 'PaperUnits', 'centimeters'); 
        set(gcf, 'PaperPosition', [0, 0, figPos(3), figPos(4)]);
        set(gcf, 'PaperSize', [figPos(3), figPos(4)]); 

        plot(time, actual_angles(:, i) * 180 / pi, '-', 'Color', resp_color, 'LineWidth', 0.8); 
        plot(time, target_angles(:, i) * 180 / pi, '--', 'Color', setpoint_color, 'LineWidth', 0.8);

        ylabel([angle_names{i}, ' ($^{\circ}$)'], 'Interpreter', 'latex', 'FontSize', 9);
        legend('测量值', '期望值', 'Location', 'best', 'Interpreter', 'tex', 'FontName', 'SimSun', 'FontSize', 9);

        grid on;
        set(gca, 'Layer', 'top', 'Box', 'on', 'TickLabelInterpreter', 'latex');

        if i == 3
            xlabel('$t$ (s)', 'Interpreter', 'latex', 'FontSize', 9);
        else
            set(gca, 'XTickLabel', []); 
        end
        
        pdf_path = sprintf('%santi_ge_yaw_%s_%s', output_folder, subfix{j}, pdf_name_subfix{i});
        print(gcf, '-dpdf', '-r300', pdf_path);
    end



    %% --- 绘图 2: 三轴角速度(Gyro)跟随曲线 ---
    gyro_names = {'$p$', '$q$', '$r$'};
    pdf_gyro_name_subfix = {'gyro_x', 'gyro_y', 'gyro_z'};


    for i = 1:3
        fig = figure;
        hold on;

        fig.Units = 'centimeters';
        figPos = [1, 1, 15, 5]; 
        fig.Position = figPos;  

        set(gcf, 'Units', 'centimeters');
        set(gcf, 'PaperUnits', 'centimeters'); 
        set(gcf, 'PaperPosition', [0, 0, figPos(3), figPos(4)]);
        set(gcf, 'PaperSize', [figPos(3), figPos(4)]); 

        plot(time, actual_gyros(:, i), '-', 'Color', resp_color, 'LineWidth', 0.8); 
        plot(time, target_gyros(:, i), '--', 'Color', setpoint_color, 'LineWidth', 0.8);

        ylabel([gyro_names{i}, ' ($^{\circ}$/s)'], 'Interpreter', 'latex', 'FontSize', 9);
        legend('测量值', '期望值', 'Location', 'best', 'Interpreter', 'tex', 'FontName', 'SimSun', 'FontSize', 9);

        grid on;
        set(gca, 'Layer', 'top', 'Box', 'on', 'TickLabelInterpreter', 'latex');

        if i == 3
            xlabel('$t$ (s)', 'Interpreter', 'latex', 'FontSize', 9);
        else
            set(gca, 'XTickLabel', []); 
        end
        
        pdf_path = sprintf('%santi_ge_yaw_%s_%s', output_folder, subfix{j}, pdf_gyro_name_subfix{i});
        print(gcf, '-dpdf', '-r300', pdf_path);
    end

end
