function sparse_diag = spdiag(size, k)
    % k specifies the diagonal offset, positive k -> diag above main diag
    if k>=1
        row = 1:1:size-k;
        col = 1+k:1:size;
    elseif k<=-1
        row = 1-k:1:size;
        col = 1:1:size+k;
    else
        row = 1:1:size;
        col = 1:1:size+k;
    end
    sparse_diag = sparse(row, col, ones(size-abs(k), 1), size, size);
end