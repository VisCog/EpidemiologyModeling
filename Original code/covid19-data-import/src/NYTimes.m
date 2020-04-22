classdef NYTimes < DataSource
% NYTIMES
%
% Description:
%   New York Times county-level dataset. Updated daily.
%
% Constructor:
%   obj = NYTimes();
%
% Inputs:
%   useCache    (optional, default = false)  Load cached data.
%
% Source:
%   https://www.nytimes.com/interactive/2020/us/coronavirus-us-cases.html
%
% See also:
%   DataSource
%   https://github.com/chadgreene/COVID19 - imports data and maps counties
%       and has detailed information on how certain locations (e.g. NYC)
%       are represented in the dataset.
%
% History:
%   17Apr2020 - SSP
% -------------------------------------------------------------------------

    properties (SetAccess = private)
        data
    end

    methods 
        function obj = NYTimes(varargin)
            url = 'https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv';
            obj@DataSource(url, varargin{:});
            obj.update();
        end

        function update(obj)
            obj.useCache = false;
            obj.data = obj.getData();
        end

        function cacheData(~)
            websave(obj.URL, [obj.DATA_DIR, 'nytimes-counties.csv']);
        end
    end
    
    % Additional dataset-specific queries
    methods
        function T = getDataByCounty(obj, countyName)
            T = obj.data(strcmpi(obj.data.county, countyName), :);
            if isempty(T)
                warning('No match for county name: %s', countyName);
            end
        end
    end
    
    methods (Access = protected)
        function T = getData(obj)
            T = obj.importData();
            T.county = string(T.county);
            T.state = string(T.state);
        end

        function importedData = importData(obj)
            if obj.useCache
                importedData = obj.loadIfExists([obj.DATA_DIR, 'nytimes-counties.csv'])
            else
                importedData = webread(obj.URL,... 
                    weboptions('TimeOut', 120, 'ContentReader', @readtable));
            end
        end

    end
end