function best_solution = genetic_algorithm(var_num, node_num, mask, c, A_eq, b_eq, A_ub, b_ub, u)
    % 遗传算法参数设置
    pop_size = 100;               % 种群大小
    num_generations = 10000;       % 迭代代数
    crossover_rate = 0.8;         % 交叉概率
    mutation_rate = 0.01;         % 变异概率
    tournament_size = 5;          % 锦标赛选择的大小
    % penalty_factor = 150;         % 违约罚金系数
    initial_penalty = 100;        % 初始罚金
    final_penalty = 150;         % 最终罚金
    elitism_count = 5;            % 精英个体数
    
    % 初始化种群（确保初始种群满足非负约束）
    population = initialize_population(pop_size, var_num, u(mask));
    
    % 计算适应度
    fitness = evaluate_fitness(population, c, A_eq, b_eq, A_ub, b_ub, initial_penalty);
    
    % 记录最佳解
    best_fitness_history = zeros(num_generations,1);
    best_solution = [];
    best_fitness_value = Inf;
    best_obj_value = Inf;  % 记录最佳配送成本（不含罚金）

    % 记录平均适应度
    average_fitness_history = zeros(num_generations,1);

    % 记录种群多样性
    fitness_std_history = zeros(num_generations,1);

    % 改进停滞
    stall_generations = 10;
    stall_counter = 0;
    prev_fitness = inf;
    termination_gen = 0;
    threshold = 220000;
    
    % 遗传算法主循环
    for gen = 1:num_generations
        % 动态调整罚金因子
        penalty_factor = initial_penalty + (final_penalty - initial_penalty) * (gen / num_generations);
        
        % 精英保留
        [sorted_fitness, sort_idx] = sort(fitness, 'ascend');
        elites = population(sort_idx(1:elitism_count), :);
        elite_fitness = sorted_fitness(1:elitism_count);
        
        % 选择（锦标赛选择）
        selected = tournament_selection(population, fitness, tournament_size);
        
        % 交叉（单点交叉）
        offspring = crossover_operator(selected, crossover_rate);
        
        % 变异（均匀变异）
        offspring = mutation_operator(offspring, mutation_rate, u(mask));
        
        % 计算子代适应度
        offspring_fitness = evaluate_fitness(offspring, c, A_eq, b_eq, A_ub, b_ub, penalty_factor);
        
        % 合并精英、子代
        combined_population = [elites; offspring];
        combined_fitness = [elite_fitness; offspring_fitness];
        
        % 更新种群：选择适应度最好的前pop_size个个体
        [sorted_fitness_combined, sort_idx_combined] = sort(combined_fitness, 'ascend');
        population = combined_population(sort_idx_combined(1:pop_size), :);
        fitness = sorted_fitness_combined(1:pop_size);

        % 更新平均适应度
        average_fitness_history(gen) = mean(fitness);

        % 更新种群多样性
        fitness_std_history(gen) = std(fitness);
        
        % 记录并更新最佳解
        if fitness(1) < best_fitness_value
            best_fitness_value = fitness(1);
            best_solution = population(1, :);
            best_obj_value = c' * best_solution';
        end
        best_fitness_history(gen) = best_fitness_value;
        
        % 显示进度
        if mod(gen, 50) == 0
            fprintf('Generation %d: Best Fitness = %.4f, Best Obj = %.4f\n', gen, best_fitness_value, best_obj_value);

            % 检查是否发生改进停滞
            if abs(prev_fitness-fitness(1)) < 1e-3
                stall_counter  = stall_counter + 1;
                % 当适应性停滞且小于阈值时
                if stall_counter == stall_generations && termination_gen == 0 && fitness(1) < threshold
                    termination_gen = gen;
                end
            end
            prev_fitness = fitness(1);
        end
    end
    
    % 显示最终结果
    disp('遗传算法优化完成。');
    disp(['最低配送成本: ', num2str(best_obj_value)]);
    disp('最优运输方案:');
    best_solution_full = zeros(node_num, node_num);
    var_idx = mask;
    best_solution_full(var_idx) = best_solution;
    disp(best_solution_full);
    
    % 绘制适应度演化图
    figure;
    plot(1:num_generations, best_fitness_history, 'b-', 'LineWidth', 2);
    hold on;
    plot(1:num_generations, average_fitness_history, 'r--', 'LineWidth', 2);
    xlabel('代数');
    ylabel('适应度值');
    title('遗传算法适应度演化');
    legend('最佳适应度', '平均适应度');
    grid on;
    hold off;
    if termination_gen > 0
        hold on;
        plot(termination_gen, best_fitness_history(termination_gen), 'ko', 'MarkerSize', 8, 'MarkerFaceColor', 'k');
        legend('最佳适应度', '平均适应度', '终止点');
        hold off;
    end

    %% 辅助函数
    
    % 初始化种群函数
    function population = initialize_population(pop_size, var_num, u_mask)
        % 向量化初始化种群，确保每个变量在[0, u_k]范围内
        population = rand(pop_size, var_num) .* u_mask';
    end
    
    % 适应度评估函数（向量化）
    function fitness = evaluate_fitness(population, c, A_eq, b_eq, A_ub, b_ub, penalty)
        % 计算目标函数值
        obj = population * c;
        
        % 计算约束违背情况
        eq_viol = A_eq * population' - repmat(b_eq, 1, size(population,1));
        eq_viol = sum(abs(eq_viol), 1)';
        
        ub_viol = A_ub * population' - repmat(b_ub, 1, size(population,1));
        ub_viol = sum(max(ub_viol, 0), 1)';
        
        lb_viol = max(-population, 0);
        lb_viol = sum(lb_viol, 2);
        
        % 计算罚金
        penalty_total = penalty * (eq_viol + ub_viol + lb_viol);
        
        % 适应度为目标函数值加罚金
        fitness = obj + penalty_total;
    end
    
    % 锦标赛选择函数（向量化）
    function selected = tournament_selection(population, fitness, tournament_size)
        pop_size = size(population, 1);
        % 随机生成锦标赛参赛者索引
        competitors = randi(pop_size, pop_size, tournament_size);
        % 找出每个锦标赛的最优个体
        [~, min_idx] = min(fitness(competitors), [], 2);
        selected = population(competitors(sub2ind(size(competitors), (1:pop_size)', min_idx)), :);
    end
    
    % 交叉操作函数（单点交叉，向量化）
    function offspring = crossover_operator(selected, crossover_rate)
        pop_size = size(selected, 1);
        var_num = size(selected, 2);
        offspring = selected;
        % 随机决定哪些个体进行交叉
        crossover_mask = rand(pop_size/2, 1) < crossover_rate;
        pairs = find(crossover_mask);
        for i = 1:length(pairs)
            parent1 = 2*pairs(i)-1;
            parent2 = 2*pairs(i);
            crossover_point = randi([1, var_num-1]);
            offspring([parent1, parent2], :) = [
                selected(parent1, 1:crossover_point), selected(parent2, crossover_point+1:end);
                selected(parent2, 1:crossover_point), selected(parent1, crossover_point+1:end)
            ];
        end
    end
    
    % 变异操作函数（均匀变异，向量化）
    function mutated = mutation_operator(offspring, mutation_rate, u_mask)
        pop_size = size(offspring, 1);
        var_num = size(offspring, 2);
        % 生成变异掩码
        mutation_mask = rand(pop_size, var_num) < mutation_rate;
        % 生成随机变异值
        random_values = rand(pop_size, var_num) .* u_mask';
        % 应用变异
        offspring(mutation_mask) = random_values(mutation_mask);
        mutated = offspring;
    end
end
