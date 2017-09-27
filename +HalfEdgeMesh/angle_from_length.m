function [alpha, d] = angle_from_length(l)

% input: edge lenths of a triangle
% output: opposite angle, degenerate

l(eps > l) = 0;
num_t = size(l, 2);

alpha = zeros(3, num_t);

r = [ ...
    l(2, :) + l(3, :) - l(1, :); ...
    l(3, :) + l(1, :) - l(2, :); ...
    l(1, :) + l(2, :) - l(3, :) ...
    ];
s = sum(l);

% make sure each column contain only one largest angle
c = (eps > r);
d = c(1, :);
for k = 2 : 3
    c1d = (c(k, :) > d);
    c(k, :) = c(k, :) & c1d;
    d = d | c1d;
end

% generate index
ind_d = find(d);
ind_nd = find(~d);

% assign the largest angle of each degenerate triangle to PI
if ~isempty(ind_d)
    alpha(:, ind_d) = c(:, ind_d) * pi;
end

% ordinary triangles
if ~isempty(ind_nd)
    r_nd = r(:, ind_nd);
    alpha(:, ind_nd) = 2 * atan( sqrt( ...
        (circshift(r_nd, [1, 0]) .* circshift(r_nd, [2, 0])) ./ r_nd ./ repmat(s(:, ind_nd), [3, 1]) ...
        ) );
end

end
