function SortedResult = sortstructure(result)
    resultcell = struct2cell(result);
    sz = size(resultcell);
    resultcell2 = reshape(resultcell, sz(1), []);
    resultcell2 = resultcell2';
    SortedResult = sortrows(resultcell2, 1);
    return

    