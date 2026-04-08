% Starch PCA Analysis (Base MATLAB version, no toolbox, anti-overlap text)
clear; clc; close all;

%% 1. Data Preparation
samples = {'6%-1','6%-2','6%-3','6%-4','7%-1','7%-2','7%-3','7%-4',...
           '8%-1','8%-2','8%-3','8%-4','9%-1','9%-2','9%-3','9%-4'};
groups = categorical({'6%','6%','6%','6%','7%','7%','7%','7%',...
                      '8%','8%','8%','8%','9%','9%','9%','9%'});

X = [
    3.749, 18.083, 40.267, 7027.6, 51.37, 6.474,  4.0, 5.0, 10.0, 5.0;
    3.113, 17.063, 44.515, 7027.6, 51.37, 2.901,  3.0, 6.0, 9.0,  2.0;
    3.679, 17.573, 42.391, 7027.6, 51.37, 3.264,  3.0, 4.0, 7.0,  5.0;
    3.513, 17.573, 42.391, 7027.6, 51.37, 4.213,  3.5, 5.4, 8.9,  4.3;
    5.164, 5.215,  30.751, 26299.0,62.42, 14.874, 9.0, 6.0, 9.0,  8.0;
    5.093, 6.015,  27.744, 26299.0,62.42, 12.013, 5.0, 7.0, 8.0,  4.0;
    5.235, 5.615,  29.248, 26299.0,62.42, 12.075, 7.0, 7.0, 3.0,  8.0;
    5.164, 5.615,  29.248, 26299.0,62.42, 12.987, 7.2, 7.0, 7.1,  6.7;
    7.357, 0.000,  23.830, 46873.0,69.89, 16.221, 8.0, 8.0, 9.0,  6.0;
    7.994, 0.000,  20.155, 46873.0,69.89, 17.453, 9.0, 9.0, 7.0,  9.0;
    8.418, 0.000,  21.993, 46873.0,69.89, 17.683, 6.0, 9.0, 2.0,  7.0;
    7.923, 0.000,  21.993, 46873.0,69.89, 17.119, 7.9, 9.5, 6.3,  7.5;
    10.257,0.000,  9.876,  55911.0,82.78, 39.442, 3.0, 9.0, 8.0,  2.0;
    14.148,0.000,  12.957, 55911.0,82.78, 41.858, 10.0,8.0, 3.0,  10.0;
    14.502,0.000,  11.417, 55911.0,82.78, 36.579, 6.0, 9.0, 2.0,  5.0;
    12.969,0.000,  11.417, 55911.0,82.78, 39.293, 6.5, 8.5, 4.0,  5.9;
];

features = {'凝胶强度', '离心析水率', '冻融析水率', '表观黏度', ...
            '屈服应力', '粘附性', '综合适用性', '颗粒均匀性', '搅拌均匀性', '质地喜好度'};

%% 2. 纯手工数学实现 Z-score 和 PCA 
mu = mean(X); 
sigma = std(X); 
Z = (X - mu) ./ sigma; 

[n, p] = size(Z);
[U, S, V] = svd(Z, 'econ');
coeff = V;                  
score = Z * coeff;          
eigenvalues = diag(S).^2 / (n - 1);         
explained = 100 * eigenvalues / sum(eigenvalues); 

coeff(:,1) = -coeff(:,1); score(:,1) = -score(:,1);

%% 3. 画图
fig1 = figure('Position', [100, 100, 900, 700], 'Color', 'w');
hold on; grid on;
colors = lines(4); 
group_names = {'6%', '7%', '8%', '9%'};

% 绘制散点与置信椭圆
for i = 1:4
    idx = (groups == group_names{i});
    scatter(score(idx,1), score(idx,2), 120, colors(i,:), 'filled', 'MarkerEdgeColor', 'k', 'DisplayName', group_names{i});
    
    group_data = score(idx, 1:2);
    if size(group_data, 1) > 2
        mu_g = mean(group_data);
        covariance = cov(group_data); 
        [V_eig, D_eig] = eig(covariance); 
        t = linspace(0, 2*pi, 100);
        a = 1.5 * sqrt(D_eig(1,1)); b = 1.5 * sqrt(D_eig(2,2)); 
        ellipse = (V_eig * [a*cos(t); b*sin(t)])' + mu_g;
        plot(ellipse(:,1), ellipse(:,2), 'Color', [colors(i,:) 0.5], 'LineWidth', 1.5, 'HandleVisibility', 'off');
        fill(ellipse(:,1), ellipse(:,2), colors(i,:), 'FaceAlpha', 0.1, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    end
end

% 绘制载荷射线与防重叠标签
scale = 5; 
% 手动指定的扇形排布目标坐标 [x, y] (保证绝对不重叠)
text_pos = [
    -2.8,  1.6;   % 1. Gel_Strength
     2.5,  0.8;   % 2. Centrifuge_Water_Loss
     2.5, -0.8;   % 3. FreezeThaw_Water_Loss
    -3.2, -0.4;   % 4. Viscosity
    -1.5,  2.2;   % 5. Yield_Stress
    -0.2,  2.5;   % 6. Adhesiveness
    -1.5, -3.2;   % 7. Applicability
    -3.0,  0.6;   % 8. Particle_Uniformity
     1.5,  1.5;   % 9. Stirring_Uniformity
     0.2, -3.5;   % 10. Texture_Preference
];

for i = 1:length(features)
    % 箭头实际尖端位置
    tip_x = coeff(i,1) * scale;
    tip_y = coeff(i,2) * scale;
    
    % 标签放置目标位置
    target_x = text_pos(i, 1);
    target_y = text_pos(i, 2);
    
    % 画实线主射线
    quiver(0, 0, tip_x, tip_y, 0, 'Color', [0.4 0.4 0.4], 'LineWidth', 1.5, 'LineStyle', '-', 'MaxHeadSize', 0.5, 'HandleVisibility', 'off');
    
    % 画虚线引导线 (从箭头尖端连到文字框边缘)
    plot([tip_x, target_x], [tip_y, target_y], 'Color', [0.6 0.6 0.6], 'LineWidth', 0.8, 'LineStyle', ':', 'HandleVisibility', 'off');
    
    % 放置文字
    text(target_x, target_y, features{i}, 'FontSize', 10, 'FontWeight', 'bold', ...
         'HorizontalAlignment', 'center', 'Interpreter', 'none', ...
         'BackgroundColor', [1 1 1 0.85], 'EdgeColor', [0.8 0.8 0.8], 'Margin', 2, 'FontName', 'SimSun');
end

% 坐标轴和图例设置
xlabel(sprintf('PC1 (%.2f%%)', explained(1)), 'FontSize', 12, 'FontName', 'Times New Roman');
ylabel(sprintf('PC2 (%.2f%%)', explained(2)), 'FontSize', 12, 'FontName', 'Times New Roman');

xline(0, '--k', 'Alpha', 0.3, 'HandleVisibility', 'off');
yline(0, '--k', 'Alpha', 0.3, 'HandleVisibility', 'off');

% 调整轴范围，以免外围的文字被裁切
axis([-5 5 -5.5 4.5]);

legend('Location', 'northeast', 'FontSize', 11, 'FontName', 'Times New Roman');
set(gca, 'FontSize', 11, 'TickDir', 'out', 'FontName', 'Times New Roman', 'LineWidth', 1.5);

%% 4. R2019a 兼容的高清导出
print(fig1, '-depsc', '-r300', 'PCA_Biplot_Fixed.eps');
disp('Successfully exported PCA_Biplot_Fixed.eps');