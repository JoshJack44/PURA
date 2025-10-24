function [seq, perm] = randseq(condMat, blockSize)
nRows = size(condMat,1);
nBlocks = nRows / blockSize;
seq = [];
perm = [];
for b = 1:nBlocks
    idx = (b-1)*blockSize+1 : b*blockSize;
    p   = randperm(blockSize);
    seq = [seq; idx(p)'];
    perm = [perm; p(:)];
end
end
