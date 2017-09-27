function [positions] = layout_voronoi(obj)
i_v_star = obj.meshTri.i_v_star;
i_e2h = obj.meshTri.i_e2h;
ledge = obj.edgeData.length;
alpha = obj.halfData.alpha;
faces = obj.meshTri.faces;
num_vert = obj.vertData.num_entry;
face_vert = obj.meshTri.face_vert;
face_link = obj.meshTri.face_link;
num_face = size(face_link, 1);

positions = zeros(3, num_vert);
markv = false(1, num_vert);
markf = false(1, num_face);

% seed a starting point, and fix its first neighbor
[seedv0] = seed_vertex(obj);
seedv1 = i_v_star(seedv0).vert(1);
positions(2, seedv1) = ledge(i_v_star(seedv0).edge(1));
markv(seedv0) = true;
markv(seedv1) = true;

% seed a starting face
[seedf1] = seed_face(face_vert, seedv0, seedv1);

layout_queue();

    function layout_queue()
        cpos = 1;
        epos = 1;
        fqueue = zeros(1, num_face);
        fqueue(cpos) = seedf1;
        vqueue = zeros(1, num_face);
        vqueue(cpos) = 0;
        while cpos <= num_face
            nface = layout_face(fqueue(cpos), vqueue(cpos));
            nface = nface(nface ~= 0);
            ndiff = setdiff(nface, fqueue(1 : epos));
            fqueue(epos+1 : epos+numel(ndiff)) = ndiff;
            markf(fqueue(cpos)) = true;
            cpos = cpos + 1;
            epos = epos + numel(ndiff);
        end
    end

    function nface = layout_face(fid, vid)
        nface = face_link(fid, :);
        if markf(fid), return; end;
        
        fv = face_vert(fid, :);
        mfv = markv(fv);
        % all covered already, or one left
        if sum(mfv) ~= 2, return; end
        v3 = fv(~mfv);
        
        halfs = faces(fid).halfs;
        a1 = 0; a2 = 0;
        v1 = 0; v2 = 0;
        for h = 1 : 3
            if halfs(h).source.index ~= v3, continue; end
            a1 = halfs(h).index;
            a2 = halfs(mod(mod(h, 3) + 1, 3) + 1).index;
            v1 = halfs(mod(h, 3) + 1).target.index;
            v2 = halfs(h).target.index;
            break;
        end
        l13 = ledge(i_e2h(a2));
        vec12 = positions(1:2, v2) - positions(1:2, v1);
        % determine direction: x12 +/- 213 = x12 -/+ 21o
        dir = 1;
        if vid ~= 0
            vec1o = positions(1:2, vid) - positions(1:2, v1);
            dir = - sign(dot(cross([1, 0], vec12), cross(vec12, vec1o)));
        end
        a1r = acos(vec12(1) / norm(vec12));
        if vec12(2) < 0, a1r = 2 * pi - a1r; end
        a1r = a1r + dir * alpha(a1);
        positions(1, v3) = l13 * cos(a1r) + positions(1, v1);
        positions(2, v3) = l13 * sin(a1r) + positions(2, v1);
        markv(v3) = true;
    end
end

function [sv0] = seed_vertex(obj)
asum = obj.vertData.angle_sum;
[~, sv0] = min(abs(asum - 2 * pi));
end

function [sf0] = seed_face(face_vert, sv0, sv1)
fv = (face_vert == sv0) | (face_vert == sv1);
s = find(sum(fv, 2) == 2);
% must be at least one
sf0 = s(1);
end
