function plotAccuracy(csvfile)
% Two clusters on x-axis: Gaze = 'at' (left), 'away' (right).
% Within each cluster: 3 bars for Visual = expand, neutral, contract.

T = readtable(csvfile);

% required columns
need = {'Visual','AudioOrder','Response','Gaze'};
if ~all(ismember(need, T.Properties.VariableNames))
    error('CSV missing columns: %s', strjoin(need, ', '));
end

% normalize case
T.Visual     = lower(strtrim(string(T.Visual)));
T.AudioOrder = lower(strtrim(string(T.AudioOrder)));
T.Response   = lower(strtrim(string(T.Response)));
T.Gaze       = lower(strtrim(string(T.Gaze)));

% response rules
correct = strings(height(T),1);
correct(T.AudioOrder=="lr") = "right";
correct(T.AudioOrder=="rl") = "left";
T.Acc = double(T.Response==correct); % 1/0

% conditions
gazeList   = ["at","away"];
visualList = ["expand","neutral","contract"];

accMeans = nan(numel(gazeList), numel(visualList)); % 2x3
accSEMs  = nan(numel(gazeList), numel(visualList)); % 2x3

for g = 1:numel(gazeList)
    for v = 1:numel(visualList)
        ix = (T.Gaze==gazeList(g)) & (T.Visual==visualList(v));
        a  = T.Acc(ix);
        if ~isempty(a)
            accMeans(g,v) = mean(a)*100;
            accSEMs(g,v)  = std(a)/sqrt(numel(a))*100;
        end
    end
end

% plot
figure('Color','w'); hold on;

clusterCenters = [1, 3];     % x positions for gaze groups
innerOffset    = [-0.25, 0, 0.25];  % offsets for 3 bars in a cluster
barW           = 0.22;

% colors per visual condition (expand/neutral/contract)
cols = [0.30 0.60 0.90;   % expand
        0.60 0.60 0.60;   % neutral
        0.90 0.40 0.40];  % contract

% draw bars + error bars
for v = 1:numel(visualList)
    % Gaze = at (left cluster)
    x1 = clusterCenters(1) + innerOffset(v);
    b1 = accMeans(1,v); 
    e1 = accSEMs(1,v);
    bar(x1, b1, barW, 'FaceColor', cols(v,:), 'EdgeColor','none');
    if ~isnan(e1), errorbar(x1, b1, e1, 'k.', 'LineWidth',1.2); end

    % Gaze = away (right cluster)
    x2 = clusterCenters(2) + innerOffset(v);
    b2 = accMeans(2,v); 
    e2 = accSEMs(2,v);
    bar(x2, b2, barW, 'FaceColor', cols(v,:), 'EdgeColor','none');
    if ~isnan(e2), errorbar(x2, b2, e2, 'k.', 'LineWidth',1.2); end
end

% axes/labels
set(gca, 'XTick', clusterCenters, 'XTickLabel', cellstr(gazeList), 'FontSize',12);
ylabel('Accuracy (%)'); xlabel('Gaze');
ylim([0 100]);
xlim([clusterCenters(1)-0.6, clusterCenters(2)+0.6]);
% legend(cellstr(visualList), 'Location','northoutside','Orientation','horizontal');
title('Accuracy');
grid on; box on;

% console summary
for g = 1:numel(gazeList)
    for v = 1:numel(visualList)
        fprintf('%s / %s : %.1f%%\n', gazeList(g), visualList(v), accMeans(g,v));
    end
end
end
