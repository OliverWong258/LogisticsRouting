function [best_solution, best_obj_value, best_fitness_history] = simulated_annealing(var_num, mask, c, A_eq, b_eq, A_ub, b_ub, u)
% SIMULATED_ANNEALING 使用模拟退火算法求解物流优化问题
% 输入参数：
%   var_num - 决策变量总数
%   node_num - 节点总数
%   mask - 逻辑矩阵，指示哪些变量是有效的（k != l）
%   c - 目标函数系数向量
%   A_eq, b_eq - 供需平衡的等式约束矩阵和向量
%   A_ub, b_ub - 运输能力上限的不等式约束矩阵和向量
%   u - 运输能力上限矩阵
% 输出参数：
%   best_solution - 最优解向量
%   best_obj_value - 最优解对应的目标函数值（不含罚金）
%   best_fitness_history - 适应度演化历史

    %% 模拟退火参数设置
    initial_temp = 1500;        % 初始温度
    final_temp = 1e-1;          % 终止温度
    alpha = 0.97;               % 降温系数
    max_iter = 1000;            % 每个温度下的最大迭代次数
    %penalty_factor = 200;       % 违约罚金系数
    initial_penalty = 100;        % 初始罚金
    final_penalty = 200;         % 最终罚金

    %% 初始化种群（初始解）
    current_solution = initialize_solution(var_num, u(mask));
    current_fitness = evaluate_fitness(current_solution, c, A_eq, b_eq, A_ub, b_ub, initial_penalty);
    current_obj = c' * current_solution';
    
    best_solution = current_solution;
    best_fitness_value = current_fitness;
    best_obj_value = current_obj;
    best_fitness_history = [];

    % 记录温度
    temperature_history = [];

    % 记录接受率
    acceptance_rate_history = [];

    % 改进停滞
    stall_generations = 50;
    stall_counter = 0;
    prev_fitness = inf;
    termination_step = 0;
    threshold = 200000;

    %% 主循环
    temp = initial_temp;
    while temp > final_temp

        % 动态调整罚金因子
        penalty_factor = initial_penalty + (final_penalty - initial_penalty) * (1 - temp / (initial_temp-final_temp));

        % 初始化接受计数器
        accept_count = 0;

        for iter = 1:max_iter
            % 生成新解（邻域解）
            new_solution = generate_neighbor(current_solution, u(mask));
            
            % 评估新解的适应度
            new_fitness = evaluate_fitness(new_solution, c, A_eq, b_eq, A_ub, b_ub, penalty_factor);
            new_obj = c' * new_solution';
            
            % 计算适应度差
            delta_fitness = new_fitness - current_fitness;
            
            % 决定是否接受新解
            if delta_fitness < 0 || rand < exp(-delta_fitness / temp)
                accept_count = accept_count + 1;
                current_solution = new_solution;
                current_fitness = new_fitness;
                current_obj = new_obj;
                
                % 更新最佳解
                if current_fitness < best_fitness_value
                    best_solution = current_solution;
                    best_fitness_value = current_fitness;
                    best_obj_value = current_obj;
                end
            end
        end
        % 记录接受率
        acceptance_rate = accept_count / max_iter;
        acceptance_rate_history = [acceptance_rate_history; acceptance_rate];

        % 记录最佳适应度
        best_fitness_history = [best_fitness_history; best_fitness_value];

        % 检查是否发生改进停滞
        if abs(prev_fitness-best_fitness_value) < 1e-3
            stall_counter  = stall_counter + 1;
            % 当适应性停滞且小于阈值时
            if stall_counter == stall_generations && termination_step == 0 && best_fitness_value < threshold
                termination_step = length(best_fitness_history);
            end
        end
        prev_fitness = best_fitness_value;

        % 降温
        temp = temp * alpha;
        temperature_history = [temperature_history; temp];
    end

    %% 显示结果
    fprintf('模拟退火优化完成。\n');
    fprintf('最低配送成本: %.4f\n', best_obj_value);
    
    figure;
    % 最佳适应度
    plot(best_fitness_history, 'b-', 'LineWidth', 2);
    hold on;
    xlabel('降温步数');
    ylabel('适应度值');
    title('模拟退火适应度演化');
    legend('最佳适应度');
    grid on;
    hold off;
    % 在绘图时添加终止点标记
    if exist('termination_step', 'var') && termination_step > 0
        hold on;
        plot(termination_step, best_fitness_history(termination_step), 'ko', 'MarkerSize', 8, 'MarkerFaceColor', 'k');
        legend('最佳适应度', '终止点');
        hold off;
    end
    
    % 温度变化
    figure;
    subplot(3,1,2);
    plot(temperature_history, 'k-', 'LineWidth', 2);
    xlabel('降温步数');
    ylabel('温度');
    title('模拟退火温度变化');
    grid on;
    
    % 接受率
    figure;
    plot(acceptance_rate_history, 'g-', 'LineWidth', 2);
    xlabel('降温步数');
    ylabel('接受率');
    title('模拟退火接受率');
    grid on;

    %% 内部辅助函数

    % 初始化解函数
    function solution = initialize_solution(var_num, u_mask)
        % 随机初始化解，确保每个变量在[0, u_k]范围内
        solution = rand(1, var_num) .* u_mask';
    end

    % 适应度评估函数
    function fitness = evaluate_fitness(x, c, A_eq, b_eq, A_ub, b_ub, penalty)
        obj = c' * x';
        
        % 计算约束违背情况
        eq_viol = A_eq * x' - b_eq;
        ub_viol = A_ub * x' - b_ub;
        lb_viol = -x';  % x >= 0
        
        % 计算罚金
        penalty_total = penalty * (sum(abs(eq_viol)) + sum(max(ub_viol, 0)) + sum(max(lb_viol, 0)));
        
        % 适应度为目标函数值加罚金
        fitness = obj + penalty_total;
    end

    % 生成邻域解函数
    function neighbor = generate_neighbor(x, u_mask)
        % 使用随机扰动生成邻域解
        perturbation = (rand(1, var_num) - 0.5) * 0.01 .* u_mask'; % 1%的随机扰动
        neighbor = x + perturbation;
        
        % 确保变量在[0, u_k]范围内
        neighbor = max(neighbor, 0);
        neighbor = min(neighbor, u_mask');
    end

end

