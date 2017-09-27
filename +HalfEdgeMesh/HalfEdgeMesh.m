classdef HalfEdgeMesh < handle
    
    properties
        edges
        faces
        halfs
        verts
        stars
        
        positions
        i_h2e
        i_e2h
        i_v_star
        i_h_st
        i_e_h2
        edge_vert
        face_link
        face_vert
    end
    
    methods
        function obj = HalfEdgeMesh(vertices, faces)
            obj.positions = vertices';
            num_faces = size(faces, 1);
            num_verts = size(vertices, 1);
            num_halfs = 3 * num_faces;
            obj.faces = repmat(HalfEdgeMesh.Face, num_faces, 1);
            obj.halfs = repmat(HalfEdgeMesh.Half, num_halfs, 1);
            obj.verts = repmat(HalfEdgeMesh.Vert, num_verts, 1);
            obj.stars = repmat(HalfEdgeMesh.Star, num_verts, 1);
            
            % re-orient triangles to make consistent half orientation
            faces = obj.reorient_face(faces);
            obj.face_vert = faces;
            
            % record neighbor face connections
            obj.face_link = obj.link_face(faces);

            % build vertices
            for v = 1 : num_verts
                obj.verts(v) = HalfEdgeMesh.Vert(v);
                obj.stars(v) = HalfEdgeMesh.Star(v);
            end
            obj.i_v_star = repmat(struct('edge',[], 'vert',[], 'half',[], 'alpha',[]), 1, num_verts);
            
            % traverse through faces
            obj.i_h_st = struct('source',zeros(1, num_halfs), 'target',zeros(1, num_halfs));
            for f = 1 : num_faces
                half1 = HalfEdgeMesh.Half(3 * f - 2);
                half2 = HalfEdgeMesh.Half(3 * f - 1);
                half3 = HalfEdgeMesh.Half(3 * f    );
                
                obj.halfs(3 * f - 2) = half1;
                obj.halfs(3 * f - 1) = half2;
                obj.halfs(3 * f    ) = half3;
                
                half1.next = half2; half1.prev = half3;
                half2.next = half3; half2.prev = half1;
                half3.next = half1; half3.prev = half2;
                half1.oppo = half1;
                half2.oppo = half2;
                half3.oppo = half3;
                
                half1.source = obj.verts(faces(f, 1));
                half2.source = obj.verts(faces(f, 2));
                half3.source = obj.verts(faces(f, 3));
                half1.target = obj.verts(faces(f, 2));
                half2.target = obj.verts(faces(f, 3));
                half3.target = obj.verts(faces(f, 1));
                
                obj.i_h_st.source(3 * f - 2) = faces(f, 1);
                obj.i_h_st.source(3 * f - 1) = faces(f, 2);
                obj.i_h_st.source(3 * f    ) = faces(f, 3);
                obj.i_h_st.target(3 * f - 2) = faces(f, 2);
                obj.i_h_st.target(3 * f - 1) = faces(f, 3);
                obj.i_h_st.target(3 * f    ) = faces(f, 1);
                
                obj.faces(f) = HalfEdgeMesh.Face(f);
                facef = obj.faces(f);
                facef.halfs = repmat(HalfEdgeMesh.Half, 3, 1);
                facef.halfs(1) = half1;
                facef.halfs(2) = half2;
                facef.halfs(3) = half3;
                
                half1.face = facef;
                half2.face = facef;
                half3.face = facef;
                
                obj.verts(faces(f, 1)).halfs = horzcat(obj.verts(faces(f, 1)).halfs, half1);
                obj.verts(faces(f, 2)).halfs = horzcat(obj.verts(faces(f, 2)).halfs, half2);
                obj.verts(faces(f, 3)).halfs = horzcat(obj.verts(faces(f, 3)).halfs, half3);
                obj.verts(faces(f, 1)).oppos = horzcat(obj.verts(faces(f, 1)).oppos, half2);
                obj.verts(faces(f, 2)).oppos = horzcat(obj.verts(faces(f, 2)).oppos, half3);
                obj.verts(faces(f, 3)).oppos = horzcat(obj.verts(faces(f, 3)).oppos, half1);
                %                 obj.i_v_star(faces(f, 1)).half = horzcat(obj.i_v_star(faces(f, 1)).half, 3 * f - 2);
                %                 obj.i_v_star(faces(f, 2)).half = horzcat(obj.i_v_star(faces(f, 2)).half, 3 * f - 1);
                %                 obj.i_v_star(faces(f, 3)).half = horzcat(obj.i_v_star(faces(f, 3)).half, 3 * f    );
                obj.i_v_star(faces(f, 1)).alpha = horzcat(obj.i_v_star(faces(f, 1)).alpha, 3 * f - 1);
                obj.i_v_star(faces(f, 2)).alpha = horzcat(obj.i_v_star(faces(f, 2)).alpha, 3 * f    );
                obj.i_v_star(faces(f, 3)).alpha = horzcat(obj.i_v_star(faces(f, 3)).alpha, 3 * f - 2);
            end
            
            % link opposite halfs
            for h = 1 : num_halfs
                v_source_index = obj.halfs(h).source.index;
                v_target_halfs = obj.halfs(h).target.halfs;
                bfound = false;
                for ht = 1 : numel(v_target_halfs)
                    if v_target_halfs(ht).target.index == v_source_index
                        obj.halfs(h).oppo = obj.halfs(v_target_halfs(ht).index);
                        bfound = true;
                        break;
                    end
                end
                % in case of parallel half pair
                if ~bfound
                    v_target_index = obj.halfs(h).target.index;
                    v_source_halfs = obj.halfs(h).source.halfs;
                    for ht = 1 : numel(v_source_halfs)
                        if v_source_halfs(ht).target.index == v_target_index ...
                                && v_source_halfs(ht).index ~= h
                            obj.halfs(h).oppo = obj.halfs(v_source_halfs(ht).index);
                            break;
                        end
                    end
                end
            end
            
            % build edges
            e_index = 0;
            obj.edges = repmat(HalfEdgeMesh.Edge, num_halfs, 1);
            obj.i_h2e = zeros(1, num_halfs);
            obj.i_e2h = zeros(1, num_halfs);
            obj.i_e_h2 = struct('first',zeros(1, num_halfs), 'second',zeros(1, num_halfs));
            for h = 1 : num_halfs
                if ~isempty(obj.halfs(h).edge)
                    obj.i_e2h(h) = obj.halfs(h).edge.index;
                else
                    e_index = e_index + 1;
                    obj.edges(e_index) = HalfEdgeMesh.Edge(e_index);
                    edgee = obj.edges(e_index);
                    edgee.halfs = repmat(HalfEdgeMesh.Half, 2, 1);
                    edgee.halfs(2) = obj.halfs(h);
                    edgee.halfs(1) = obj.halfs(h).oppo;
                    obj.i_h2e(e_index) = h;
                    obj.halfs(h).edge = edgee;
                    obj.halfs(h).oppo.edge = edgee;
                    obj.i_e_h2.first(e_index) = h;
                    obj.i_e_h2.second(e_index) = obj.halfs(h).oppo.index;
                    v1 = obj.halfs(h).source.index;
                    v2 = obj.halfs(h).target.index;
                    obj.i_v_star(v1).edge = horzcat(obj.i_v_star(v1).edge, e_index);
                    obj.i_v_star(v1).vert = horzcat(obj.i_v_star(v1).vert, v2);
                    obj.i_v_star(v2).edge = horzcat(obj.i_v_star(v2).edge, e_index);
                    obj.i_v_star(v2).vert = horzcat(obj.i_v_star(v2).vert, v1);
                    obj.i_e2h(h) = e_index;
                end
            end
            obj.edges = obj.edges(1 : e_index);
            obj.i_h2e = obj.i_h2e(1 : e_index);
            obj.i_e_h2.first = obj.i_e_h2.first(1 : e_index);
            obj.i_e_h2.second = obj.i_e_h2.second(1 : e_index);
            
            obj.edge_vert = obj.edge_table();
        end
        
        %         function build_star(obj)
        %             num_vert = numel(obj.verts);
        %             for v = 1 : num_vert
        %                 alpha = obj.i_v_star(v).alpha;
        %                 vert = obj.i_v_star(v).vert;
        %                 nn = numel(alpha);
        %                 ov = ones(1, nn);
        %                 cnt = 1;
        %                 ncp = 1;
        %                 while true
        %                     nt = obj.halfs(alpha(ncp)).target.index;
        %                     ncp = find(vert == nt);
        %                     if 1 == ncp
        %                         break;
        %                     end
        %                     cnt = cnt + 1;
        %                     ov(cnt) = ncp;
        %                 end
        %                 so{v} = ov;
        %             end
        %         end
        
        function pos = position(obj, index)
            pos = obj.positions(:, index);
        end
        
        function e = edge(obj, index)
            e = obj.edges(index);
        end
        
        function f = face(obj, index)
            f = obj.faces(index);
        end
        
        function h = half(obj, index)
            h = obj.halfs(index);
        end
        
        function v = vert(obj, index)
            v = obj.verts(index);
        end
        
        function h = face_half(obj, f, h)
            h = obj.faces(f).halfs(h);
        end
        
        % num_vert x num_vert
        function vm = star_table(obj)
            vm = zeros(numel(obj.verts), numel(obj.verts));
            for h = 1 : numel(obj.halfs)
                si = obj.halfs(h).source.index;
                ti = obj.halfs(h).target.index;
                vm(h, si) = vm(h, si) + 1;
                vm(h, ti) = vm(h, ti) - 1;
            end
        end
        
        % num_vert x num_edge, column major
        function em = edge_table(obj)
            em = false(numel(obj.verts), numel(obj.edges));
            for e = 1 : numel(obj.edges)
                si = obj.edges(e).halfs(1).source.index;
                ti = obj.edges(e).halfs(1).target.index;
                em(si, e) = true;
                em(ti, e) = true;
            end
        end
        
        % num_vert x num_face, column major
        function fmv = face_table_vert(obj)
            fmv = false(numel(obj.verts), numel(obj.faces));
            for f = 1 : numel(obj.faces)
                f1 = obj.faces(f).halfs(1).source.index;
                f2 = obj.faces(f).halfs(2).source.index;
                f3 = obj.faces(f).halfs(3).source.index;
                fmv(f1, f) = true;
                fmv(f2, f) = true;
                fmv(f3, f) = true;
            end
        end
        
        % num_edge x num_face, column major
        function fme = face_table_edge(obj)
            fme = false(numel(obj.edges), numel(obj.faces));
            for f = 1 : numel(obj.faces)
                f1 = obj.faces(f).halfs(1).edge.index;
                f2 = obj.faces(f).halfs(2).edge.index;
                f3 = obj.faces(f).halfs(3).edge.index;
                fme(f1, f) = true;
                fme(f2, f) = true;
                fme(f3, f) = true;
            end
        end
        
        % return all boundary vertices
        function [bv, verts] = boundary_verts(obj)
            bv = false(numel(obj.verts), 1);
            for v = 1 : numel(obj.verts)
                bv(v) = obj.is_boundary_vert(v);
            end
            verts = obj.halfs(bv);
        end
        
        % return all boundary halfs
        function [bh, halfs] = boundary_halfs(obj)
            bh = false(numel(obj.halfs), 1);
            for h = 1 : numel(obj.halfs)
                bh(h) = obj.is_boundary_half(h);
            end
            halfs = obj.halfs(bh);
        end
        
        % check if the vertex is a boundary
        function [b, bn] = is_boundary_vert(obj, index)
            v_h = obj.verts(index).halfs;
            bn = false(1, numel(v_h));
            for h = 1 : numel(v_h)
                if obj.is_boundary_half(v_h(h).index)
                    bn(h) = true; % only one half, for regular mesh
                end
            end
            b = any(bn);
        end
        
        % check if the half is a boundary
        function b = is_boundary_half(obj, index)
            b = (obj.halfs(index).index == obj.halfs(index).oppo.index);
        end
        
        % check if the edge is a boundary
        function b = is_boundary_edge(obj, index)
            b = is_boundary_half(obj.edge(index).halfs(1));
        end
        
        % order 1-star neighbors using half direction
        function star_order(obj)
            num_vert = numel(obj.verts);
            for v = 1 : num_vert
                alpha = obj.i_v_star(v).alpha;
                edge = obj.i_v_star(v).edge;
                vert = obj.i_v_star(v).vert;
                for ai = 1 : numel(alpha)
                    nis = find(vert == obj.halfs(alpha(ai)).source.index);
                    nit = find(vert == obj.halfs(alpha(ai)).target.index);
                    if nis > nit
                        tmp = vert(nis);
                        vert(nit+1 : nis) = vert(nit : nis-1);
                        vert(nit) = tmp;
                        tmp = edge(nis);
                        edge(nit+1 : nis) = edge(nit : nis-1);
                        edge(nit) = tmp;
                    end
                end
                obj.i_v_star(v).edge = edge;
                obj.i_v_star(v).vert = vert;
                newa = zeros(1, numel(alpha));
                for ai = 1 : numel(alpha)
                    newa(vert == obj.halfs(alpha(ai)).source.index) = alpha(ai);
                end
                obj.i_v_star(v).alpha = newa;
            end
        end
    end
    
    methods(Static)
        function flink = link_face(faces)
            flink = zeros(size(faces));
            num_f = size(faces, 1);
            for f = 1 : num_f
                for v = 1 : 3
                    v1 = faces(f, v);
                    v2 = faces(f, mod(v, 3) + 1);
                    fv = (faces == v1) | (faces == v2);
                    s = find(sum(fv, 2) == 2);
                    if numel(s) == 2
                        flink(f, v) = s(s ~= f);
                    end
                end
            end
        end
        
        function faces = reorient_face(faces)
            num_f = size(faces, 1);
            fqueue = zeros(1, num_f);
            fqueue(1) = 1;
            fmark = false(1, num_f);
            fmark(1) = true;
            cp = 1;
            np = 2;
            while np <= num_f
                f0 = faces(cp, :);
                for v = 1 : 3
                    v1 = faces(cp, v);
                    v2i = mod(v, 3) + 1;
                    v2 = faces(cp, v2i);
                    fv = (faces == v1) | (faces == v2);
                    s = find(sum(fv, 2) == 2);
                    if numel(s) == 1, continue; end
                    fni = s(s ~= cp);
                    
                    if fmark(fni), continue; end
                    fn = faces(fni, :);
                    vn1i = find(fn == v1);
                    vn2i = find(fn == v2);
                    fncs = circshift(fn, v - vn1i, 2);
                    if f0([v, v2i]) == fncs([v, v2i])
                        faces(fni, [vn1i, vn2i]) = faces(fni, [vn2i, vn1i]);
                    end
                    fqueue(np) = fni;
                    fmark(fni) = true;
                    np = np + 1;
                end
                cp = cp + 1;
            end
        end
    end
end
