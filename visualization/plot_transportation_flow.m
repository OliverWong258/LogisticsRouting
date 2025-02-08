function plot_transportation_flow(supply_num, nodes, solution_full, title_str)
    % PLOT_TRANSPORTATION_FLOW 绘制运输路径（使用热图颜色表示运输量）
    % 输入参数：
    %   nodes - 节点坐标矩阵 (node_num x 2)
    %   solution_full - 运输方案矩阵 (node_num x node_num)
    %   title_str - 图表标题
    
    figure;
    hold on;
    grid on;
    xlabel('X 坐标');
    ylabel('Y 坐标');
    title(title_str);
    
    
    % 绘制仓库和客户
    scatter(nodes(1:supply_num,1), nodes(1:supply_num,2), 100, 'filled', 'b', 'DisplayName', '仓库'); % 仓库
    scatter(nodes(supply_num+1:end,1), nodes(supply_num+1:end,2), 100, 'filled', 'r', 'DisplayName', '客户'); % 客户
    
    % 标注节点编号
    for i = 1:size(nodes,1)
        text(nodes(i,1)+1, nodes(i,2)+1, num2str(i), 'FontSize', 8);
    end
    
    % 提取运输路径及其对应的流量
    % 提取运输路径的源节点和目标节点
    [source, target] = find(solution_full > 0);
    
    % 使用线性索引从 solution_full 中提取实际的运输量
    flow = solution_full(sub2ind(size(solution_full), source, target));

    % 获取最大和最小流量以进行归一化
    max_flow = max(flow);
    min_flow = min(flow);
    
    % 选择一个颜色映射，例如 jet
    cmap = jet(256);
    
    if max_flow == min_flow
        % 如果所有流量相同，使用中间颜色
        normalized_flow = round(size(cmap,1)/2) * ones(size(flow));
    else
        % 归一化流量到 [1, size(cmap,1)]
        normalized_flow = round( (flow - min_flow) / (max_flow - min_flow) * (size(cmap,1)-1) ) + 1;
        % 确保归一化后的值在有效范围内
        normalized_flow(normalized_flow < 1) = 1;
        normalized_flow(normalized_flow > size(cmap,1)) = size(cmap,1);
    end
    
    % 绘制运输路径
    for idx = 1:length(source)
        s = source(idx);
        t = target(idx);
        f = flow(idx);
        color = cmap(normalized_flow(idx), :);
        plot([nodes(s,1), nodes(t,1)], [nodes(s,2), nodes(t,2)], ...
             'Color', color, 'LineWidth', 1 + f/20);
    end
    
    % 添加颜色条
    colormap(cmap);
    c = colorbar;
    c.Label.String = '运输量';
    %disp(min_flow);
    %disp(max_flow);
    clim([min_flow, max_flow]);
    
    legend('仓库', '客户', 'Location', 'bestoutside');
    hold off;
end
