clc,clear;
addpath(genpath('./visualization'));

% 从 'logistics_data.mat' 文件加载变量
load('./data/logistics_data.mat');

method = input('请输入要使用的方法（1代表两阶段发，2代表遗传算法，3代表模拟退火算法）：');

if method == 1
    load('./data/two_phase_simplex.mat');
    plot_title = '两阶段法供需平衡误差';
elseif method == 2
    load('./data/genetic_algorithm.mat');
    plot_title = '遗传算法供需平衡误差';
elseif method == 3
    load('./data/simulated_annealing.mat');
    plot_title = '模拟退火算法供需平衡误差';
else
    disp('方法不存在');
end

violation = calculate_ub_violation(x(1:var_num), A_ub, b_ub);

if isempty(violation)
    disp('没有违背运输上限的情况');
    return
end
disp(violation)