function y = semifullcells2doubles(x)
    % SEMIFULLCELLS2DOUBLES
    %
    % Description:
    %   Converts a cell array with a mixture of cells with doubles and
    %   empty cells ([]) to array of doubles where empty cells are
    %   represented with NaN. Makes indexing easier if each entry isn't a
    %   distinct cell.
    %
    % Syntax:
    %   y = semifullcells2doubles(x)
    %
    % Inputs:
    %   x   Nx1 array ('cell')
    %            Contents: doubles or chars that can convert to doubles
    % Outputs:
    %   y   Nx1 array ('double')
    %
    % History:
    %   16Apr2020 - SSP
    %   22Apr2020 - SSP - Added support for arrays w/ char and empty cells
    % ---------------------------------------------------------------------

    assert(isa(x, 'cell'), 'Input x must be a cell array!')
    y = nan(size(x));
    ind = cellfun(@(x) ~isempty(x), x);
    if ischar(x{1})
        y(ind) = cat(1, cellfun(@str2double, x(ind)));
    else
        y(ind) = cat(1, x{ind});
    end

