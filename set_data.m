%% 一、 定义实验数据
supply_num = 8; % 仓库个数
client_num = 12; % 客户个数

% 节点编号从1到node_num，其中1-supply_num为仓库，supply_num+1-node_num为客户
% 每行表示一个节点的 [x, y] 坐标
nodes = [
    10, 50;   % 节点1：仓库
    20, 60;   % 节点2：仓库
    30, 40;   % 节点3：仓库
    40, 70;   % 节点4：仓库
    50, 55;   % 节点5：仓库
    60, 65;   % 节点6：仓库
    70, 45;   % 节点7：仓库
    80, 60;   % 节点8：仓库
    15, 25;   % 节点9：客户
    25, 35;   % 节点10：客户
    35, 15;   % 节点11：客户
    45, 25;   % 节点12：客户
    55, 45;   % 节点13：客户
    65, 30;   % 节点14：客户
    75, 50;   % 节点15：客户
    85, 40;   % 节点16：客户
    95, 55;   % 节点17：客户
    105, 35;  % 节点18：客户
    115, 50;  % 节点19：客户
    125, 45;  % 节点20：客户
];
% 仓库供给量
supply = [200; 120; 90; 150; 95; 130; 155; 115];
% 客户需求量
demand = [85; 95; 75; 65; 120; 100; 80; 70; 110; 90; 60; 105];

node_num = supply_num + client_num; % 节点总个数
var_num = node_num*(node_num-1); % 决策变量总数

%% 定义从决策变量索引 var_idx 到 (i,j) 的映射函数
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

%% 二、计算配送成本矩阵 c_kl
% 配送成本与距离成正比，比例系数 alpha = 2 元/吨·km
alpha = 2;

% 初始化距离矩阵
distance = zeros(node_num,node_num);

% 计算所有节点之间的欧氏距离
for k = 1:node_num
    for l = 1:node_num
        if k ~= l
            distance(k,l) = sqrt( (nodes(k,1) - nodes(l,1))^2 + (nodes(k,2) - nodes(l,2))^2 );
        else
            distance(k,l) = 0;  % 自己到自己的距离为0
        end
    end
end

% 计算配送成本矩阵 c_kl
cost_matrix = alpha * distance;

%% 三、定义运输能力上限矩阵 u_kl
% 初始化运输能力上限矩阵
u = zeros(node_num,node_num);

rng(0); % 设置随机种子，因而每次运行产生的随机数都是相同的
for k = 1:(node_num-1)
    for l = (k+1):node_num
        if k <= supply_num && l > supply_num
            % 仓库到客户
            u(k,l) = randi([10, 30]);  % 增大运输能力上限
            u(l,k) = u(k,l);
        elseif k <= supply_num && l <= supply_num
            % 仓库到仓库
            u(k,l) = randi([30, 60]);
            u(l,k) = u(k,l);
        % elseif k > supply_num && l <= supply_num
        %     % 客户到仓库
        %     u(k,l) = randi([20, 80]);
        %     u(l,k) = u(k,l);
        elseif k > supply_num && l > supply_num
            % 客户到客户
            u(k,l) = randi([50, 150]);
            u(l,k) = u(k,l);
        end
    end
end

%% 四、构建目标函数系数向量 c
% 共有node_num个节点，每个节点到其他node_num-1个节点的配送变量，共var_num个变量
% 变量顺序为 x_{1,2}, x_{1,3}, ..., x_{1,node_num}, x_{2,1}, x_{2,3}, ..., x_{node_num,node_num-1}

% 创建逻辑掩码，排除 x_{k,k} 变量
mask = ~eye(node_num);  % 逻辑矩阵，真表示 k != l

% 目标函数系数向量 c（var_numx1）
c = cost_matrix(mask);  % 只包含 k != l 的 c_{kl}

%% 五、构建供需平衡约束矩阵 A_eq 和向量 b_eq
% A_eq 是node_num*var_num的矩阵，每行对应一个节点的供需平衡
A_eq = zeros(node_num, node_num*(node_num-1));

% b_eq 是node_numx1的向量，对应每个节点的供需情况
% 前supply_num个为供给量，后client_num个为负的需求量
b_eq = [supply; -demand];

% 构建A_eq矩阵
for node_idx = 1:node_num
    for var_idx = 1:var_num
        [i,j] = get_nodes(var_idx, node_num);
        if i == node_idx
            A_eq(node_idx, var_idx) = 1;
        elseif j == node_idx 
            A_eq(node_idx, var_idx) = -1;
        end
    end
end

%% 六、构建运输能力上限约束矩阵 A_ub 和向量 b_ub
% A_ub 是var_num*var_num的矩阵，对应 x_{k,l} <= u_{k,l}
A_ub = eye(node_num*(node_num-1));  % 单位矩阵，每个变量对应一个约束
b_ub = u(mask);      % 将运输能力上限矩阵按列展开为var_numx1向量

% 保存变量到 'logistics_data.mat' 文件，以供之后加载
save('./data/logistics_data.mat', 'supply_num', 'client_num', 'nodes', 'supply', 'demand', 'node_num', "var_num", ...
    "mask", "c", "A_eq", "b_eq", "A_ub", "b_ub", "u");

disp('变量已成功保存到 logistics_data.mat 文件。');
