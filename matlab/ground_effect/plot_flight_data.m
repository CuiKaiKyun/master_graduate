clc;
clear;
close all;

file_name = 'flight_data/flight_data.csv'
data = readtable(file_name);
motor_out = data.('motorOut')'
vol = data.('betteryVoltage')'
time = data.('time')'

figure;
plot(time, motor_out);
figure;
plot(time, vol);