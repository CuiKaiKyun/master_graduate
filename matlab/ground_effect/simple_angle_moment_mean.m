clc;
clear;
close all;

input_file = 'cs_torque_data/force_sensor_300mm.csv'
% 读取数据
data = readtable(input_file);

% 假设列名就是'surface angle(deg)'和'moment'
angles = data.('surfaceAngle_deg_');
speed = data.('rotorSpeed_rad_s_');
moment(:, 1) = data.('moment_x_N_m_');
moment(:, 2) = data.('moment_y_N_m_');
moment(:, 3) = data.('moment_z_N_m_');
force(:, 1) = data.('force_x_N_');
force(:, 2) = data.('force_y_N_');
force(:, 3) = data.('force_z_N_');

plot(moment(:, 3));
xlabel('cs angle');
ylabel('$moment_z\mathrm{(N\cdot m)}$');

length = size(speed);
length = length(1);
% 目标角度
target_angles = [-20, -18, -16, -14, -12, -10, -8, -6, -4, -2, 0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20];
angles_num = size(target_angles);
angles_num = angles_num(2);

moment_cali_sum = zeros(1, 3);
force_cali_sum = zeros(1, 3);
cali_count = 0;
% 校准力矩
for j = 1:length
    if speed(j) == 0
        moment_cali_sum = moment_cali_sum + moment(j, :);
        force_cali_sum = force_cali_sum + force(j, :);
        cali_count = cali_count + 1;
    end
end
force_cali_mean = force_cali_sum / cali_count;
moment_cali_mean = moment_cali_sum / cali_count;

force_sum = zeros(angles_num, 3);
moment_sum = zeros(angles_num, 3);
force_mean = zeros(angles_num, 3);
moment_mean = zeros(angles_num, 3);
count_val = zeros(angles_num, 1);
% 计算结果
for i = 1:angles_num
    for j = 1:length
        if target_angles(i) == angles(j) && speed(j) > 0
            force_sum(i, :) = force_sum(i, :) + force(j, :);
            moment_sum(i, :) = moment_sum(i, :) + moment(j, :);
            count_val(i) = count_val(i) + 1;
        end
    end
    force_mean(i, :) = force_sum(i, :)./count_val(i);
    moment_mean(i, :) = moment_sum(i, :)./count_val(i);
end

result = [target_angles',force_mean, moment_mean, count_val];

cali_result = [target_angles',force_mean-force_cali_mean, moment_mean-moment_cali_mean, count_val];


% 创建列标题
columnNames = {'surfaceAngle_deg_', 'force_x', 'force_y', 'force_z', 'moment_x', 'moment_y', 'moment_z', 'count'};

% 转换为table并添加列标题
dataTable = array2table(cali_result, 'VariableNames', columnNames);

% 保存为CSV文件
% 分解文件名
[pathstr, name, ext] = fileparts(input_file);

% 添加后缀并重新组合
suffix = '_processed';
newFile = fullfile(pathstr, [name, suffix, ext]);
writetable(dataTable, newFile);
