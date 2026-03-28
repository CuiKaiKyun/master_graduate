clc;
clear;
close all;

file_name = 'rotor_thrust_data/rotor_thrust_raw_data_battery_2.csv'
data = readtable(file_name);
rotor_speed_raw = data.('rotorSpeed_rad_s_')'
vol = data.('battery_vol_V_')'
time = data.('time_s_')'

% 滤波器参数
fc = 1;        % 截止频率 (Hz)
fs = 1000;      % 采样频率 (Hz)

% 计算alpha
alpha = 1 / (1 + (1/(2*pi*fc/fs))); % 精确公式
% 或者近似：alpha = fc / (fc + fs/(2*pi));

% 一阶低通滤波
vol_fil = filter(alpha, [1, alpha-1], vol, vol(1)*(1-alpha));

figure;
plot(time, rotor_speed_raw);
figure;
plot(time, vol);
hold on;
plot(time, vol_fil);