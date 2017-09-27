function [positions, seedi] = layout_vertices_from_la(obj)
num_vert = obj.vertData.num_entry;
i_v_star = obj.meshTri.i_v_star;
ledge = obj.edgeData.length;
alpha = obj.halfData.alpha;

positions = zeros(3, num_vert);
markv = false(1, num_vert);

seedi = seed_vertex(obj);
s0vec = zeros(3, 1);
markv(seedi) = true;
layout_queue();

    function layout_queue()
        cpos = 1;
        epos = 1;
        lqueue = zeros(1, num_vert);
        lqueue(cpos) = seedi;
        while cpos <= num_vert
            nvert = layout_span(lqueue(cpos));
            ndiff = setdiff(nvert, lqueue(1 : cpos));
            lqueue(epos+1 : epos+numel(ndiff)) = ndiff;
            cpos = cpos + 1;
            epos = epos + numel(ndiff);
        end
        debug_draw(lqueue);
    end

    function vert = layout_span(cen)
        vert = i_v_star(cen).vert;
        % boundary vertex must have been reached
        if obj.meshTri.is_boundary_vert(cen), return; end
        
        nn = numel(vert);
        n0 = 0; n1 = 0;
        for v = 1 : nn % find the 1st vertex already been layout
            if markv(vert(v))
                if n0 == 0
                    n0 = v;
                else
                    n1 = v;
                    break;
                end
            end
        end
        if n0 == 0 % no vertices are layout
            layout_seed(cen);
            return;
        end
        if n1 == 0
            error('isolated vertex');
        end
        
        nl = ledge(i_v_star(cen).edge);
        na = alpha(i_v_star(cen).alpha);
%         if numel(na) < numel(nl) % add a complementary to make it circular traversable
%             na = horzcat(na, 2 * pi - sum(na));
%         end
        n0vec = positions(:, vert(n0)) - positions(:, cen);
        n1vec = positions(:, vert(n1)) - positions(:, cen);
        cvec = positions(:, cen) - positions(:, seedi);
        dir = sign(dot(s0vec, n0vec) * dot(n0vec, n1vec));
        acs = acos(dot(s0vec, n0vec) / norm(s0vec) / norm(n0vec));
        acs = acs + dir * na(n0);
        nc = mod(n0, nn) + 1;
        while nc ~= n0
            vid = vert(nc);
            pos = zeros(3, 1);
            pos(1) = nl(nc) * cos(acs) + cvec(1);
            pos(2) = nl(nc) * sin(acs) + cvec(2);
            if ~markv(vid)
                positions(:, vid) = pos;
                markv(vid) = true;
            else
                if 1e-2 < norm(positions(:, vid) - pos)
                    disp(horzcat(positions(:, vid), pos));
                end
            end
            acs = acs + dir * na(nc);
            nc = mod(nc, nn) + 1;
        end
    end

    function vert = layout_seed(cen)
        vert = i_v_star(cen).vert;
        nn = numel(vert);
        nl = ledge(i_v_star(cen).edge);
        na = alpha(i_v_star(cen).alpha);
        acs = 0;
        for v = 1 : nn
            vid = vert(v);
            positions(1, vid) = nl(v) * cos(acs);
            positions(2, vid) = nl(v) * sin(acs);
            markv(vid) = true;
            acs = acs + na(v);
        end
        s0vec = positions(:, vert(1)) - positions(:, cen);
    end

    function debug_draw(lqueue)
        scrsz = get(0, 'ScreenSize');
        scrsz = [50 50 scrsz(3)-100 scrsz(4)-150];
        plot_row = floor(scrsz(4) / 300);
        plot_col = floor(scrsz(3) / 300);
        plot_num = min(plot_row * plot_col, num_vert);
        figure('Position',scrsz);
        set(gcf, 'Color', 'w');
        for spi = 1 : plot_num
            draw_star(lqueue(spi), spi);
        end
        
        function draw_star(cen, spi)
            if spi > 16, return; end;
            vert = i_v_star(cen).vert;
            nn = numel(vert);
            clrn = cool(nn);
            Utility.subaxis(plot_row, plot_col, spi, 'Spacing',0, 'Margin',0.05);
            plot(positions(1, :), positions(2, :), 'k*');
            for v = 1 : nn
                line(positions(1, [cen, vert(v)]), positions(2, [cen, vert(v)]), 'color',clrn(v, :));
            end
            hold on;
            inner_index = find(~obj.meshTri.boundary_verts());
            plot(positions(1, inner_index), positions(2, inner_index), 'ro');
            lm = max(max(abs(positions))) * 1.1;
            xlim([-lm lm]);
            ylim([-lm lm]);
        end
    end

end

function sid = seed_vertex(obj)
asum = obj.vertData.angle_sum;
[~, sid] = min(abs(asum - 2 * pi));
end
