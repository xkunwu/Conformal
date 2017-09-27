fclose('all'); close all hidden; clear classes; clc;
dbstop if error;
addpath('d:\Projects\DERIVESTsuite\');

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
% 
% hexm = HalfEdgeMesh.HalfEdgeMesh(verts, faces);
% hexd = ConvexAngleSum.DataTri(hexm);
% 
% ConvexAngleSum.optimize_angle_sum_energy(hexd);

modelName = 'maxplanck_5b';
% modelName = 'maxplanck_1b';
% modelName = 'maxplanck_0.02b';
% modelName = 'box';
% modelName = 'pyramid';
% modelName = 'prism';
obj = HalfEdgeMesh.readObj(sprintf('Data/%s.obj', modelName));
mesh = HalfEdgeMesh.HalfEdgeMesh(obj.v, obj.f.v);
meshop = ConvexAngleSum.DataTri(mesh);

% alpha = meshop.compute_angle();
% angle_sum = meshop.angle_sum();
% meshop.compute_cotan_weight();
% cotLap = meshop.cot_Laplacian();

ut = ConvexAngleSum.optimize_angle_sum_energy(meshop);
angle_sum = meshop.angle_sum();
% [npos, si] = ConvexAngleSum.layout_vertices_from_la(meshop);
[npos] = ConvexAngleSum.layout_voronoi(meshop);

obj_o = obj;
obj_o.v = npos';
% obj_o.v = npos' + repmat(obj_o.v(si, :), [size(obj_o.v, 1), 1]);
HalfEdgeMesh.writeObj(sprintf('Data/%s_flat.obj', modelName), obj_o);
