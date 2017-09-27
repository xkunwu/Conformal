fclose('all'); close all hidden; clear classes; clc;

% %      1---2
% %     / \ / \
% %    6---3---4
% %     \ / \ /
% %      5---7
% %
% verts = rand(7, 3);
% % verts(2, :) = verts(3, :);
% faces = rand(6, 3);
% faces(1, :) = [3 1 2];
% faces(2, :) = [3 2 4];
% faces(3, :) = [3 4 7];
% faces(4, :) = [3 7 5];
% faces(5, :) = [3 5 6];
% faces(6, :) = [3 6 1];


%       3
%      /|\
%     2-5-4
%      \|/
%       1
verts(5, :) = [0 0 0];
verts(4, :) = [1 0 0];
verts(3, :) = [0 1 0];
verts(2, :) = [-1 0 0];
verts(1, :) = [0 -1 0];
faces(4, :) = [5 4 3];
faces(3, :) = [5 1 4];
faces(2, :) = [5 2 1];
faces(1, :) = [5 3 2];


% %     4
% %     |\
% %     1-2,3
% %     |/
% %     5
% verts(5, :) = [0 -1 0];
% verts(4, :) = [0 1 0];
% verts(3, :) = [1 0 0];
% verts(2, :) = [1 0 0];
% verts(1, :) = [0 0 0];
% faces(4, :) = [1 5 2];
% faces(3, :) = [1 4 5];
% faces(2, :) = [1 3 4];
% faces(1, :) = [1 2 3];

hexm = HalfEdgeMesh.HalfEdgeMesh(verts, faces);
hexm.star_order();
hexd = ConvexAngleSum.DataTri(hexm);
l = hexd.compute_edge_length();
alpha = hexd.compute_angle();
[cotw, cota] = hexd.compute_cotan_weight();
asum = hexd.angle_sum();
cotLap = hexd.cot_Laplacian();

ConvexAngleSum.optimize_angle_sum_energy(hexd);
angle_sum = hexd.angle_sum();
[npos, si] = ConvexAngleSum.layout_vertices_from_la(hexd);

obj_o.v = npos';
obj_o.f.v = faces;
HalfEdgeMesh.writeObj('Data/test_flat.obj', obj_o);
