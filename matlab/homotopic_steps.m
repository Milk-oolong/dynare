function [info,number_of_calls] = homotopic_steps(tdx,positive_var_indx,shocks,init_weight,step,init,number_of_calls)
global oo_
number_of_calls = number_of_calls + 1;
max_number_of_calls = 50;
if number_of_calls>max_number_of_calls
    info = NaN;
    return
end
max_iter = 100;
weight   = init_weight;
verbose  = 0;
iter     = 0;
time     = 0;
reduce_step = 0;
while iter<=max_iter &&  weight<=1
    iter = iter+1;
    old_weight = weight;
    weight = weight+step;
    oo_.exo_simul(tdx,positive_var_indx) = weight*shocks+(1-weight);
    if init
        info = perfect_foresight_simulation(oo_.dr,oo_.steady_state);
    else
        info = perfect_foresight_simulation;
    end
    time = time+info.time;
    if verbose
        [iter,step]
        [info.iterations.time,info.iterations.error]
    end
    if ~info.convergence
        if verbose
            disp('Reduce step size!')
        end
        reduce_step = 1;
        break
    else
        if length(info.iterations.error)<5
            if verbose
                disp('Increase step size!')
            end
            step = step*1.5;
        end
    end
end
if reduce_step
    step=step/1.5;
    [info,number_of_calls] = homotopic_steps(tdx,positive_var_indx,shocks,old_weight,step,init,number_of_calls);
    if ~isnan(info)
        time = time+info.time;
        return
    else
        return
    end
end
if weight<1 && iter<max_iter
    oo_.exo_simul(tdx,positive_var_indx) = shocks;
    if init
        info = perfect_foresight_simulation(oo_.dr,oo_.steady_state);
    else
        info = perfect_foresight_simulation;
    end
    info.time = info.time+time;
else
    info.time = time;
end