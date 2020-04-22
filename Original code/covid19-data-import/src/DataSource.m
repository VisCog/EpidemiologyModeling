classdef (Abstract) DataSource < handle
% DATASOURCE
%
% Constructor:
%   obj = DataSource(url, useCache)
%
% Inputs:
%   url         (char) URL to import data from
%                   Passed to DataSource subclasses
%   useCache    (optional, default = false)  Used cache instead of import
%
% See also:
%   CovidTrackingProject, EuroCDC
%
% History:
%   16Apr2020 - SSP
% ------------------------------------------------------------------------

    properties (SetAccess = private)
        URL
    end
    
    properties (SetAccess = protected)
        useCache
    end

    properties (Hidden, Constant)
        DATA_DIR = [fileparts(fileparts(mfilename('fullpath'))),... 
                    filesep, 'data', filesep];
    end

    methods (Abstract, Access = protected)
        getData(obj, useCache);
        importData(obj);
    end

    methods (Abstract, Access = public) 
        update(obj);
        cacheData(obj);
    end

    methods 
        function obj = DataSource(url, useCache)
            obj.URL = url;
            if nargin < 2
                obj.useCache = false;
            else
                assert(islogical(useCache), 'useCache must be true/false');
                obj.useCache = useCache;
            end
        end
    end

    % A few small convinience methods that were used by several subclasses
    methods (Static, Access = protected)
        function tf = isSemifull(col)
            % ISSEMIFULL  Whether column is semifull cell array
            if isa(col, 'cell') && nnz(cellfun(@isempty, col)) > 0
                tf = true;
            else
                tf = false;
            end
        end

        function opts = getWebOptions()
            % GETWEBOPTIONS  Preferences for webread
            opts = weboptions('Timeout', 120,...
                'ContentType', 'json',...
                'ContentReader', @loadjson);
        end

        function data =  loadIfExists(filePath)
            % LOADIFEXISTS  Checks whether file exists before importing
            if exist(filePath, 'file')
                data = loadjson(filePath);
            else
                error('File not found: %s', filePath);
            end
        end
    end
end