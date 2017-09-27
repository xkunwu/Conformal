function ut = optimize_angle_sum_energy(obj)

num_vert = obj.vertData.num_entry;

u0 = obj.vertData.u;
l0 = obj.compute_edge_length();

in_num = zeros(1, num_vert);
for v = 1 : num_vert
    in_num(v) = numel(obj.meshTri.i_v_star(v).alpha);
end

inner_index = find(~obj.meshTri.boundary_verts());
if isempty(inner_index)
    disp('no inner vertex!');
    return;
end
u_inner = u0(inner_index);
Theta = zeros(1, num_vert);
Theta(inner_index) = 2 * pi;
Theta_inner = Theta(inner_index);

% [~, g, H] = angle_sum_energy_u(u_inner)
% % abs(g - gradest(@angle_sum_energy_u, u_inner))
% H_ad = hessian(@angle_sum_energy_u, u_inner)
% abs(H - H_ad)
% return;

% options = optimoptions(@fminunc, 'GradObj','on', 'Hessian','on', 'Display','iter-detailed', 'DerivativeCheck','on');
options = optimoptions(@fminunc, 'GradObj','on', 'Hessian','on', 'Display','iter-detailed');
% options = optimoptions(@fminunc, 'GradObj','on', 'Display','iter-detailed');
% [ut_inner, fval, exitflag, output] = fminunc(@angle_sum_energy_u, u_inner, options)
[ut_inner, ~, ~, ~] = fminunc(@angle_sum_energy_u, u_inner, options);
ut = zeros(1, num_vert);
ut(inner_index) = ut_inner;
obj.update_length(l0, ut);
obj.compute_angle();

    function [val, g, H] = angle_sum_energy_u(u_inner)
        u = zeros(1, num_vert);
        u(inner_index) = u_inner;
        [~, lambda] = obj.update_length(l0, u);
        alpha = obj.compute_angle();
        
        alpha = alpha(:)';
        lambda = lambda(obj.meshTri.i_e2h);
        lambda(isinf(lambda)) = 0;
        
        alpha_lambda = dot(alpha, lambda) / 2;
        loba = 0;
        for i = 1 : numel(alpha)
            loba = loba + lobachevsky(alpha(i));
        end
        usum = - dot(in_num, u) * pi / 2;
        Theta_u = dot(Theta_inner, u_inner) / 2;
        val = alpha_lambda + loba + usum + Theta_u;
        
        % gradient
        if nargout > 1
            asum = obj.angle_sum();
            g = angle_sum_gradient(asum(inner_index));
        end
        
        % hessian
        if nargout > 2
            obj.compute_cotan_weight();
            cotLap = obj.cot_Laplacian();
            H = angle_sum_hessian(cotLap(inner_index, inner_index));
        end
    end

    function la = lobachevsky(a)
        if (eps > abs(mod(a, pi))) || (eps > abs(mod(a, pi) - pi))
            la = 0;
        else
            l_f = @(t) log( abs(2 * sin(t)) );
            la = - integral(l_f, 0, a);
        end
    end

    function g = angle_sum_gradient(angle_sum)
        g = (Theta_inner - angle_sum) / 2;
    end

    function H = angle_sum_hessian(cotLap)
        H = cotLap / 2;
    end
end
