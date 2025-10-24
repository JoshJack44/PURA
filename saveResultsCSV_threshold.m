function saveResultsCSV_threshold(results, fname)
n = size(results,1);
Trial        = nan(n,1);
Hemifield    = strings(n,1);
SC           = strings(n,1);
AudioOrder   = strings(n,1);
DegOffset    = strings(n,1);
Response     = strings(n,1);
RT           = nan(n,1);
Correct      = strings(n,1);

for i = 1:n
    if ~isempty(results{i,1}), Trial(i)        = results{i,1}; end
    if ~isempty(results{i,2}), Hemifield(i)    = string(results{i,2}); end
    if ~isempty(results{i,3}), SC(i)           = results{i,3}; end
    if ~isempty(results{i,4}), AudioOrder(i)   = string(results{i,4}); end
    if ~isempty(results{i,5}), DegOffset(i)    = results{i,5}; end
    if ~isempty(results{i,6}), Response(i)     = string(results{i,6}); end
    if ~isempty(results{i,7}), RT(i)           = results{i,7}; end
    if ~isempty(results{i,8}), Correct(i)      = results{i,8}; end
end

T = table(Trial, Hemifield, SC, AudioOrder, DegOffset, Response, RT, Correct);
writetable(T, fname);
fprintf('Saved CSV: %s\n', fname);
end
