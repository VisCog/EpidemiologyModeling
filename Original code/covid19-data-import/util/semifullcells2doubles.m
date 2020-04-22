function y = semifullcells2doubles(x)
    % SEMIFULLCELLS2DOUBLES
    %
    % Description:
    %   Converts a cell array with a mixture of cells with doubles and
    %   empty cells ([]) to array of doubles where empty cells are
    %   represented with NaN. Makes indexing easier if each entry isn't a
    %   distinct cell.
    %
    % Inputs:
    %   x   Nx1 array ('cell')
    % Outputs:
    %   y   Nx1 array ('double')
    %
    % Syntax:
    %   y = semifullcells2doubles(x)
    %
    % History:
    %   16Apr2020 - SSP
    % ---------------------------------------------------------------------

    assert(isa(x, 'cell'), 'Input x must be a cell array!')
    y = nan(size(x));
    ind = cellfun(@(x) ~isempty(x), x);
    y(ind) = cat(1, x{ind});

