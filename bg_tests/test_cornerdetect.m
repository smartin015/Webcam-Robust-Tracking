pframe = imread('tough1.jpg');
frame = imread('tough2.jpg');

points1 = detectFASTFeatures(pframe);
points2 = detectFASTFeatures(frame);
[features1, valid_points1] = extractFeatures(pframe, points1);
[features2, valid_points2] = extractFeatures(frame, points2);
indexPairs = matchFeatures(features1, features2);

matched_points1 = valid_points1(indexPairs(:, 1), :);
matched_points2 = valid_points2(indexPairs(:, 2), :);

gte = vision.GeometricTransformEstimator;
gte.Transform = 'Nonreflective similarity';
[tform inlierIdx] = step(gte, matched_points2.Location, matched_points1.Location);
figure; showMatchedFeatures(pframe,frame,matched_points1(inlierIdx),matched_points2(inlierIdx));
title('Matching inliers'); legend('inliersIn', 'inliersOut');

delta = mean(matched_points2(inlierIdx).Location - matched_points1(inlierIdx).Location);
disp(delta);