% 计算供需平衡误差
function balance_error = calculate_balance_error(x, A_eq, b_eq)
    balance = A_eq * x' - b_eq;
    balance_error = abs(balance);
end

