classdef DataTri < handle
    
    properties
        meshTri
        edgeData
        faceData
        halfData
        vertData
    end
    
    methods
        function obj = DataTri(meshTri)
            obj.meshTri = meshTri;
            obj.edgeData = ConvexAngleSum.DataTri.Edge(numel(meshTri.edges));
            obj.faceData = ConvexAngleSum.DataTri.Face(numel(meshTri.faces));
            obj.halfData = ConvexAngleSum.DataTri.Half(numel(meshTri.halfs));
            obj.vertData = ConvexAngleSum.DataTri.Vert(numel(meshTri.verts));
        end
        
        % norm 2 of edge
        function l = edge_length(obj, index)
            edge = obj.meshTri.edge(index);
            half = edge.halfs(1);
            source = obj.meshTri.position(half.source.index, :);
            target = obj.meshTri.position(half.target.index, :);
            l = norm(target - source);
        end
        
        % norm 2 of all edges
        function l = compute_edge_length(obj)
            source = obj.meshTri.positions(:, obj.meshTri.i_h_st.source);
            target = obj.meshTri.positions(:, obj.meshTri.i_h_st.target);
            source = (target - source) .^ 2;
            l = sqrt(sum(source));
            obj.halfData.length = l;
            l = l(obj.meshTri.i_h2e);
            obj.edgeData.length = l;
            obj.edgeData.lambda = 2 * log(obj.edgeData.length);
        end
        
        % set new length of all edges
        function set_edge_length(obj, l)
            obj.edgeData.length = l;
            obj.halfData.length = l(obj.meshTri.i_e2h);
        end
        
        function [l, lambda] = update_length(obj, l0, u0)
            lambda0 = 2 * log(l0);
            lambda = lambda0 + u0 * obj.meshTri.edge_vert;
            l = exp(lambda / 2);
            obj.set_edge_length(l);
        end
        
        % compute angles for this face
        function [alpha, d] = compute_face_angle(obj, index)
            face = obj.meshTri.face(index);
            l = [ ...
                obj.edgeData.length(face.halfs(1).edge.index), ...
                obj.edgeData.length(face.halfs(2).edge.index), ...
                obj.edgeData.length(face.halfs(3).edge.index), ...
                ];
            
            [alpha, d] = HalfEdgeMesh.angle_from_length(l);
            for k = 1 : 3
                obj.halfData.alpha(face.halfs(k).index) = alpha(k);
            end
        end
        
        % compute all angles in radians
        function [alpha, d] = compute_angle(obj)
            num_face = obj.faceData.num_entry;
            l = reshape(obj.halfData.length, [3, num_face]);
            [alpha, d] = HalfEdgeMesh.angle_from_length(l);
            obj.halfData.alpha = alpha(:)';
        end
        
        % compute cotan weights for each eage
        function [cotw, cota] = compute_cotan_weight(obj)
            cota = obj.halfData.alpha;
            mpi = (eps > abs(mod(cota, pi))) | (eps > abs(mod(cota, pi) - pi));
            cota(mpi) = 0;
            cota(~mpi) = cot(cota(~mpi));
            obj.halfData.cota = cota;
            i_e_h2 = obj.meshTri.i_e_h2;
            cotw = (cota(i_e_h2.first) + cota(i_e_h2.second)) / 2;
            obj.edgeData.cotw = cotw;
        end
        
        % compute angle sum for each vertex
        function angle_sum = angle_sum(obj)
            num_vert = obj.vertData.num_entry;
            angle_sum = zeros(1, num_vert);
            for v = 1 : num_vert
                i_v_alpha = obj.meshTri.i_v_star(v).alpha;
                asum = sum(obj.halfData.alpha(i_v_alpha));
                obj.vertData.angle_sum(v) = asum;
                angle_sum(v) = asum;
            end
        end
        
        % cot-Laplace operator
        function cotLap = cot_Laplacian(obj)
            cotLap = zeros(numel(obj.meshTri.verts));
            num_verts = numel(obj.meshTri.i_v_star);
            for v = 1 : num_verts
                w = obj.edgeData.cotw(obj.meshTri.i_v_star(v).edge);
                t = obj.meshTri.i_v_star(v).vert;
                for i = 1 : numel(t)
                    cotLap(v, v) = cotLap(v, v) + w(i);
                    cotLap(v, t(i)) = cotLap(v, t(i)) - w(i);
                end
            end
        end
    end
    
    methods(Static)
        % logarithmic length
        function lambda = log_length(length)
            lambda = 2 * log(length);
        end
    end
end
