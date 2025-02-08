% 计算运输能力违背
function ub_violation = calculate_ub_violation(x, A_ub, b_ub)
    violation = A_ub * x' - b_ub;
    ub_violation = violation(violation > 0);
end