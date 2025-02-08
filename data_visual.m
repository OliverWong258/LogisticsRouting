% 从 'logistics_data.mat' 文件加载变量
load('logistics_data.mat');

% 验证变量是否已加载
disp('变量已成功从 logistics_data.mat 文件加载：');
disp(['仓库个数 (supply_num): ', num2str(supply_num)]);
disp(['客户个数 (client_num): ', num2str(client_num)]);
disp('仓库供给量 (supply):');
disp(supply);
disp('客户需求量 (demand):');
disp(demand);

node_num = supply_num + client_num; % 总节点数

% 创建一个新的图形窗口
figure;
hold on;

% 绘制仓库位置
scatter(nodes(1:supply_num, 1), nodes(1:supply_num, 2), 100, 'r', 's', 'filled', 'DisplayName', '仓库');
% 'r' 表示红色，'s' 表示方形标记，'filled' 表示填充颜色

% 绘制客户位置
scatter(nodes(supply_num+1:end, 1), nodes(supply_num+1:end, 2), 100, 'b', 'o', 'filled', 'DisplayName', '客户');
% 'b' 表示蓝色，'o' 表示圆形标记，'filled' 表示填充颜色

% 为每个仓库添加标签，显示其编号和供给量
for i = 1:supply_num
    text(nodes(i,1) + 1, nodes(i,2) + 1, sprintf('W%d\n供给: %d', i, supply(i)), 'FontSize', 8, 'Color', 'r');
end

% 为每个客户添加标签，显示其编号和需求量
for i = 1:client_num
    node_idx = supply_num + i;
    text(nodes(node_idx,1) + 1, nodes(node_idx,2) + 1, sprintf('C%d\n需求: %d', i, demand(i)), 'FontSize', 8, 'Color', 'b');
end

% 设置图形标题和轴标签
title('物流最优化问题：仓库与客户位置分布');
xlabel('X 坐标');
ylabel('Y 坐标');

% 显示图例
legend('Location', 'best');

% 设置轴比例相等，以保持图形比例
axis equal;

grid on;

hold off; 
