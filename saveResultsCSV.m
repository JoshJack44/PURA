function saveResultsCSV(results)
n = size(results,1);
Trial        = nan(n,1);
Visual       = strings(n,1);
Hemifield    = strings(n,1);
AudioOrder   = strings(n,1);
Response     = strings(n,1);
RT           = nan(n,1);

for i = 1:n
    if ~isempty(results{i,1}), Trial(i)      = results{i,1}; end
    if ~isempty(results{i,2}), Visual(i)     = string(results{i,2}); end
    if ~isempty(results{i,3}), Hemifield(i)  = string(results{i,3}); end
    if ~isempty(results{i,4}), AudioOrder(i) = string(results{i,4}); end
    if ~isempty(results{i,5}), Response(i)   = string(results{i,5}); end
    if ~isempty(results{i,6}), RT(i)         = results{i,6}; end
end

T = table(Trial, Visual, Hemifield, AudioOrder, Response, RT);

ts = datestr(now,'yyyymmdd_HHMMSS');
fname = sprintf('results_%s.csv', ts);
writetable(T, fname);
fprintf('Saved CSV: %s\n', fname);
end
