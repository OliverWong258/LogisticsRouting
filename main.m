clc,clear;
addpath(genpath('./methods'));

%% 一、从配置文件加载实验数据
% 从 'logistics_data.mat' 文件加载变量
load('./data/logistics_data.mat');

% 验证变量是否已加载
disp('变量已成功从 logistics_data.mat 文件加载：');
disp(['仓库个数 (supply_num): ', num2str(supply_num)]);
disp(['客户个数 (client_num): ', num2str(client_num)]);
disp('仓库供给量 (supply):');
disp(supply);
disp('客户需求量 (demand):');
disp(demand);

%% 二、求解
method = input('请输入要使用的方法（1代表两阶段发，2代表遗传算法，3代表模拟退火算法）：');

if method == 1
    tic
    % 定义松弛变量数量
    num_slack = size(A_ub, 1);

    % 扩展目标函数系数向量 c，松弛变量的系数为0
    c_final = [c; zeros(num_slack, 1)];

    % 构建松弛变量对应的单位矩阵
    I_slack = eye(num_slack);

    % 扩展供需平衡约束矩阵 A_eq，添加松弛变量部分为0
    A_eq_extended = [A_eq, zeros(size(A_eq, 1), num_slack)];

    % 将不等式约束转换为等式约束，添加松弛变量对应的单位矩阵
    A_ub_extended = [A_ub, I_slack];

    % 合并等式和不等式约束
    A_final = [A_eq_extended; A_ub_extended];

    % 合并供需平衡和运输能力上限的约束向量
    b_final = [b_eq; b_ub];

    x=two_phase_simplex(A_final,b_final,c_final');
    toc
    x=x(:,1:var_num);
    save('./data/two_phase_simplex.mat', 'x');
    disp('最优成本：');
    disp(c'*x');
elseif method == 2
    tic
    x = genetic_algorithm(var_num, node_num, mask, c, A_eq, b_eq, A_ub, b_ub, u);
    save('./data/genetic_algorithm.mat', 'x');
    toc
elseif method == 3
    tic
    [x, best_obj_value, best_fitness_history] = simulated_annealing(var_num, mask, c, A_eq, b_eq, A_ub, b_ub, u);
    save('./data/simulated_annealing.mat', 'x');
    toc
else
    disp('方法不存在');
    return;
end
