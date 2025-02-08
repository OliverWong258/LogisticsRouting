clc,clear;
addpath(genpath('./visualization'));

% 从 'logistics_data.mat' 文件加载变量
load('./data/logistics_data.mat');

data1 = load('./data/two_phase_simplex.mat');
data2 = load('./data/genetic_algorithm.mat');
data3 = load('./data/simulated_annealing.mat');

best_solution_sa = data3.x;
best_solution_ga = data2.x;
best_solution_tp = data1.x;

balance_error_sa = calculate_balance_error(best_solution_sa, A_eq, b_eq);
balance_error_ga = calculate_balance_error(best_solution_ga, A_eq, b_eq);
balance_error_tp = calculate_balance_error(best_solution_tp, A_eq, b_eq);

% 绘制误差条形图
figure;
bar([balance_error_sa, balance_error_ga, balance_error_tp]);
disp(node_num);
set(gca, 'XTick', 1:node_num);
xlabel('节点编号');
ylabel('供需平衡误差');
title('各算法供需平衡误差比较');
legend('模拟退火', '遗传算法', '两阶段法', 'Location', 'best');
grid on;