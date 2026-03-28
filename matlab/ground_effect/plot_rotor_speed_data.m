% 该脚本用于比较目标转速和当前转速之间的跟随关系

clc;
clear;
close all;

file_name = 'rotor_speed/rotor_speed_raw_data_12V.csv'
data = readtable(file_name);
rotor_speed = data.('rotorSpeed_rad_s_')';target_rotor_speed = data.('targetRotorSpeed_rad_s_')';
vol = data.('batteryVoltage_V_')';
equivalentOutput = data.('equivalentOutput');
Output = data.('motorOutput');
time = data.('time_s_')';

figure;
plot(time, rotor_speed);
hold on;
plot(time, target_rotor_speed);
figure;
plot(time, vol);
figure;
plot(time, Output);


