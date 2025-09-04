function M = expmat(varargin)
levels = varargin;
nF = numel(levels);
[M{1:nF}] = ndgrid(levels{:});
for k = 1:nF
    M{k} = M{k}(:);
end
M = [M{:}];
end
