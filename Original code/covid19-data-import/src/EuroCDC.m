classdef EuroCDC < DataSource
% EUROCDC
%
% Constructor:
%   obj = EuroCDC();
%
% Inputs:
%   useCache    (optional, default = false)  Load cached data.
%
% Source:
%   https://www.ecdc.europa.eu/en/geographical-distribution-2019-ncov-cases
%
% See also:
%   DataSource
%
% History:
%   16Apr2020 - SSP
% ------------------------------------------------------------------------

    properties (SetAccess = private)
        data
    end

    methods 
        function obj = EuroCDC(varargin)
            url = 'https://opendata.ecdc.europa.eu/covid19/casedistribution/json/';
            obj@DataSource(url, varargin{:});
            obj.update();
        end

        function update(obj)
            obj.data = obj.getData();
        end

        function cacheData(obj)
            websave([obj.DATA_DIR, 'european-countries.json'], obj.URL);
            fprintf('\tEuroCDC: Saved to %s\n',... 
                [obj.DATA_DIR, 'european-countries.json']);
        end
    end

    % Additional dataset-specific queries
    methods 
        function T = getDataByCountry(obj, countryName)
            % GETDATABYCOUNTRY
            %
            % Input:
            %   countryName     (char)
            %
            % Example:
            %   T = obj.getDataByCountry('canada');
            % ------------------------------------------------------------
            T = obj.data(strcmpi(obj.data.countriesAndTerritories, countryName), :);
            if isempty(T)
                warning('%s not found!', countryName);
            end
        end

        function T = getDataByDate(obj, dateInput)
            % GETDATABYDATE
            % 
            % Input:
            %   dateInput   (char) Must be valid input to datestr function
            %
            % Examples:
            %   T = obj.getDataByDate('4-Apr-2020');
            %
            % See also:
            %   datestr
            % ------------------------------------------------------------
            try
                dateInput = datestr(dateInput);
            catch
                error('dateInput should be a valid input to datestr!');
            end
            T = obj.data(obj.data.dateRep == dateInput, :);
        end
    end

    methods (Access = protected)
        function cachedData = loadCache(obj)
            cachedData = obj.loadIfExists([obj.DATA_DIR, 'european-countries.json']);
        end

        function importedData = importData(obj)
            if obj.useCache
                importedData = obj.loadIfExists([obj.DATA_DIR, 'european-countries.json']);
            else
                importedData = webread(obj.URL, obj.getWebOptions());
            end
        end

        function T = getData(obj)
            fprintf('\tEuroCDC: Importing data... ');
            if obj.useCache
                importedData = obj.loadCache();
            else
                importedData = webread(obj.URL, obj.getWebOptions);
            end

            fprintf('Parsing data... ');
            T = struct2table(cat(1, importedData.records{:}));
            T.dateRep = datetime(T.dateRep);
            T.day = str2double(T.day);
            T.month = str2double(T.month);
            T.year = str2double(T.year);
            T.cases = str2double(T.cases);
            T.deaths = str2double(T.deaths);
            T.popData2018 = str2double(T.popData2018);
            fprintf('Done!\n');
        end
    end
end