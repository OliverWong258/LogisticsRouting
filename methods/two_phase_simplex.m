function x=two_phase_simplex(coefMatrix,constraintVec,objectiveCoef)
    % 使用两阶段单纯形法求解线性规划的最优解。适用于约束矩阵 coefMatrix 中不一定包含一个 m 阶单位矩阵的情况。
    % 目标：最小化 objectiveCoef * x
    % 约束条件：coefMatrix * x = constraintVec, x >= 0
    % 其中 coefMatrix 为 m×n 矩阵，constraintVec 为 m 维列向量，objectiveCoef 为 n 维行向量
    
    %% 初始化阶段：构建第一阶段的单纯形表
    [numConstraints,numVariables]=size(coefMatrix);
    basisIndices=((numVariables+1):(numVariables+numConstraints))';                                 % 初始基变量的索引
    basisCosts=ones(1,numConstraints);                                                              % 基变量对应的目标函数系数 (辅助目标函数为求和)
    reducedCosts=basisCosts*coefMatrix;                                                             % 获取非单位矩阵对应检验数
    currentValue=basisCosts*constraintVec;                                                          % 计算当前的函数值
    simplexTable=[basisIndices coefMatrix eye(numConstraints) constraintVec;
                 0 reducedCosts zeros(1,numConstraints) currentValue];                              % 构建初始化单纯形表
    
    %% 第一阶段：寻找辅助问题的最优解
    iter1 = 0;
    while any(simplexTable(numConstraints+1,2:(numConstraints+numVariables+1))>0) 
        % 获取当前的检验数
        reducedCosts=simplexTable(numConstraints+1,2:(numConstraints+numVariables+1));                                            
        % 选择检验数最大的变量作为进入基的变量
        [~ , enteringIdx]=max(reducedCosts);                                                    
           enteringColumn=simplexTable(1:numConstraints,enteringIdx+1); 
        % 寻找允许的出基变量
        [positiveEntries ,J]=find(enteringColumn'>0);                                                 
        if isempty(positiveEntries)                                                        
            error('问题不存在最优解');                                         
        end
        % 计算比值，选择最小比值对应的行作为出基变量
        ratios=simplexTable(1:numConstraints,numConstraints+numVariables+2);                                                    
        [~, minRatioIdx]=min(ratios(J)./enteringColumn(J));                                             
        leavingRow=J(minRatioIdx);   
        % 生成初等行变换矩阵 (确保 E * enteringColumn = e_r)
        pivotColumn=simplexTable(:,enteringIdx+1);                                                        
        E=create_pivot_matrix(pivotColumn,leavingRow);                                                                                                                                    
        whole1=E*simplexTable(:,2:(numConstraints+numVariables+2));                                            
        basisIndices(leavingRow)=enteringIdx;             
        % 更新单纯形表
        simplexTable=[[basisIndices;0] whole1]; 
        iter1 = iter1 + 1;
    end
    %% 检查第一阶段的结果，判断是否存在可行解
    if abs(simplexTable(end,end))==0                                                  
    [~,artificialVars]=find(basisIndices'>numVariables);                                                    
    % 检查是否有人工变量仍在基中，并进行驱赶
    if ~isempty(artificialVars)                                                            
        cols=size(artificialVars,2);                                                          
        del=zeros(1,cols);                                                        
        for i=1:cols
            % 寻找非人工变量以替换当前基中的人工变量
            nonZeroCols=find(simplexTable(artificialVars(i),2:numVariables+1));                                       
            if ~isempty(nonZeroCols)                                                   
                 pivotCol=nonZeroCols(1);                                                    
                 E1=create_pivot_matrix(simplexTable(:,pivotCol+1),artificialVars(i));                                 
                 whole1=E1*E*simplexTable(:,2:(numConstraints+numVariables+2));                                
                 basisIndices(artificialVars(i))=enteringIdx;                                               
                 simplexTable=[[basisIndices;0] whole1];                                      
            else
                 del(i)=1;                                                    
            end
        end
        ind=setdiff(1:numConstraints,artificialVars(logical(del)));                                    
        simplexTable=simplexTable(ind,[1:(numVariables+1) numConstraints+numVariables+2]);                                       
    else
        simplexTable=simplexTable(1:(end-1),[1:(numVariables+1) numConstraints+numVariables+2]);                                
    end
    else
        error('原问题不存在可行解');
    end
    
    %% 构建第二阶段的单纯形表
    [m , n]=size(simplexTable);
    reducedCostsPhase2=objectiveCoef(simplexTable(:,1))*simplexTable(:,2:(n-1))-objectiveCoef;                                    
    currentValuePhase2=objectiveCoef(simplexTable(:,1))*simplexTable(:,n);                                               
    simplexTablePhase2=[simplexTable;[0 reducedCostsPhase2 currentValuePhase2]];                                               
    basisIndices=simplexTable(1:m,1);                  
    
    %% 第二阶段：优化目标函数
    iter2 = 0;
    while any(simplexTablePhase2(m+1,2:(n-1))>0)                                          
        % 获取当前的检验数 
        reducedCosts=simplexTablePhase2(m+1,2:(n-1));                                           
        % 选择检验数最大的变量作为进入基的变量 
        [~ , enteringIdx]=max(reducedCosts);                                                   
        enteringColumn=simplexTablePhase2(1:m,enteringIdx+1);                                                   
        % 寻找允许的出基变量
        [positiveEntries , J]=find(enteringColumn'>0);                                                 
        if isempty(positiveEntries)                                                        
            error('问题不存在最优解');                                          
        end
        % 计算比值，选择最小比值对应的行作为出基变量
        ratios=simplexTablePhase2(1:m,n);                                                     
        [~, minRatioIdx]=min(ratios(J)./enteringColumn(J));                                             
        leavingRow=J(minRatioIdx);
        % 生成初等行变换矩阵 (确保 E * enteringColumn = e_r)
        pivotColumn=simplexTablePhase2(:,enteringIdx+1);                                                        
        E=create_pivot_matrix(pivotColumn,leavingRow);                                                          
        whole3=E*simplexTablePhase2(:,2:(n));                                             
        basisIndices(leavingRow)=enteringIdx;     
        % 更新单纯形表
        simplexTablePhase2=[[basisIndices;0] whole3];
        iter2 = iter2 + 1;
    end
    
    %% 提取最优解
    [finalRows,finalCols]=size(simplexTablePhase2);
    basisIndices=simplexTablePhase2(1:finalRows-1,1);
    numOriginalVars=finalCols-2;
    x=zeros(1,numOriginalVars);
    for i=1:finalRows-1
        x(basisIndices(i))=simplexTablePhase2(i,finalCols);
    end
    disp('第一阶段迭代次数：');
    disp(iter1);
    disp('第二阶段迭代次数：');
    disp(iter2);
end

function E=create_pivot_matrix(columnVector,pivotRow)
    % 创建初等矩阵，使得 E * columnVector = e_pivotRow
    % columnVector: 用于生成初等矩阵的列向量
    % pivotRow: 要进行变换的行号
    %
    % 如果 columnVector(pivotRow) == 0，则返回 -1 表示无法生成有效的矩阵
    numRows=size(columnVector,1);                                                               
    if abs(columnVector(pivotRow))==0                                                         
        E=-1;
    else
        E=eye(numRows);
        transformationVector=-columnVector;
        transformationVector(pivotRow)=1;
        transformationVector=transformationVector./(columnVector(pivotRow));
        E(:,pivotRow)=transformationVector;
    end
end


