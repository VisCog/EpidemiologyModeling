classdef Citymapper < DataSource
% CITYMAPPER
%
% Description:
%   Citymapper City Mobility Index (CMI) datasets
%
% Constructor:
%   obj = CityMapper();
%
% Inputs:
%   useCache    (optional, default = false)  Load cached data.
%
% Methods:
%   cityNames = obj.getCities()
%       Lists city names with available data.
%   dateRange = obj.getCityDateRange(cityName)
%       Returns range of lowest and highest non-NaN values
%
% Source:
%   https://citymapper.com/cmi/
%
% History:
%   22Apr2020 - SSP
% -------------------------------------------------------------------------

    properties (SetAccess = private)
        data
    end

    methods 
        function obj = Citymapper(varargin)
            % Note: The URL changes every day with a datestring like '20200422'
            url = sprintf('https://cdn.citymapper.com/data/cmi/Citymapper_Mobility_Index_%s.csv',... 
                datestr(now, 'yyyymmdd'));

            obj@DataSource(url, varargin{:});
            obj.update();
        end

        function update(obj)
            obj.data = obj.getData();
        end

        function cacheData(obj)
            websave([obj.DATA_DIR, 'citymapper.csv'], obj.URL);
        end
    end

    % Additional dataset-specific queries
    methods 
        function cityNames = getCities(obj)
            % GETCITIES  Lists city names with data available
            cityNames = string(obj.data.Properties.VariableNames(2:end)');
        end

        function dateRange = getCityDateRange(obj, cityName)
            % GETCITYDATERANGE  Provides date of first and last non-NaN
            %   Useful for xlim of graphs
            %
            % Inputs:
            %   cityName        (char) Any of the CMI dataset city names
            %
            % Example:
            %   dateRange = obj.getCityDateRange('Seattle');
            % ------------------------------------------------------------
            assert(ismember(cityName, obj.data.Properties.VariableNames),...
                sprintf('CITYMAPPER: %s - invalid city name!', cityName));
            dateRange = [...
                min(obj.data.Date(~isnan(obj.data.(cityName)))),...
                max(obj.data.Date(~isnan(obj.data.(cityName))))];
        end
    end

    methods (Access = protected)
        function importedData = importData(obj)
            opts = delimitedTextImportOptions(...
                'VariableNamesLine', 4,... 
                'DataLines', 5);
            if obj.useCache
                importedData = readtable([obj.DATA_DIR, 'citymapper.csv'], opts);
            else
                csvOptions = weboptions(...
                    'TimeOut', 120,... 
                    'ContentReader', @(x) readtable(x, opts));
                importedData = webread(obj.URL, csvOptions);
            end
        end

        function data = getData(obj)
            warning('off', 'MATLAB:table:ModifiedAndSavedVarnames');
            data = obj.importData();
            data.Date = datetime(data.Date);
            params = data.Properties.VariableNames;
            for i = 2:numel(params)
                data.(params{i}) = semifullcells2doubles(data.(params{i}));
            end
        end

    end
end