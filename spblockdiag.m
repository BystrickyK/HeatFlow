function sparse_matrix = spblockdiag(A, blocksize, k)
    % k specifies the diagonal block offset, positive k -> diag above main diag
    % Only for square matrices
    
    [row, col] = size(A);
    
    total_rows = row * blocksize;
    total_cols = col * blocksize;
    
    sparse_matrix = sparse(total_rows, total_cols);
    
    idx.row = 1:row:total_rows;  % row index of the top-left elements of each block
    idx.col = 1:col:total_cols;  % col --||--
    
    if k>0
        idx.col = idx.col + blocksize - 1;
        idx.col = idx.col(1:end-k);
        idx.row = idx.row(1:end-k);
    elseif k<0
        idx.row = idx.col + blocksize - 1;
        idx.col = idx.col(1:end-abs(k));
        idx.row = idx.row(1:end-abs(k));
    end
    
    
    for block_i = 1 : blocksize-abs(k)
        r = idx.row(block_i);
        c = idx.col(block_i);
        sparse_matrix(r:r+row-1, c:c+col-1) = A;
    end
    
        