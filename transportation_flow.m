clc,clear;
addpath(genpath('./visualization'));

% 加载坐标
load('./data/logistics_data.mat');

% 加载最优解
method = input('请输入要加载的最优解（1代表两阶段发，2代表遗传算法，3代表模拟退火算法）：');

if method == 1
    load('./data/two_phase_simplex.mat');
    plot_title = '两阶段法运输路径';
    node_num = supply_num + client_num;
    var_num = node_num*(node_num-1);
    
    best_solution_full = zeros(node_num, node_num);

    for var_idx = 1:var_num
        [i,j] = get_nodes(var_idx, node_num);
        best_solution_full(i,j) = x(var_idx);
    end

    % 绘制各算法的运输路径
    plot_transportation_flow(supply_num, nodes, best_solution_full, plot_title);
elseif method == 2
    load('./data/genetic_algorithm.mat');
    plot_title = '遗传算法矩阵热图';
elseif method == 3
    load('./data/simulated_annealing.mat');
    plot_title = '模拟退火算法矩阵热图';
else
    disp('方法不存在');
end


% 将向量解转换为矩阵形式
best_solution_full = zeros(node_num, node_num);
best_solution_full(mask) = x;

% 绘制热图
figure;
imagesc(best_solution_full);
colorbar;
title(plot_title);
xlabel('目标节点');
ylabel('源节点');

%% 辅助函数 
% 定义从决策变量索引 var_idx 到 (i,j) 的映射函数
function [i, j] = get_nodes(var_idx, node_num)    
    % 计算 i
    i = ceil(var_idx /(node_num-1));

    % 计算 j
    pos_in_i = var_idx - (i -1)*(node_num-1);
    if pos_in_i <i
        j = pos_in_i;
    else
        j = pos_in_i +1;
    end
end
