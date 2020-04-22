classdef CovidTrackingProject < DataSource
% COVIDTRACKINGPROJECT
%
% Constructor:
%   obj = CovidTrackingProject(useCache);
%
% Inputs:
%   useCache    (optional, default = false)  Load cached data.
%
% Source:
%   https://covidtracking.com/api
%
% See also:
%   DataSource
%
% History:
%   16Apr2020 - SSP
% ------------------------------------------------------------------------

    properties (SetAccess = private)
        stateData
        nationData
    end

    methods
        function obj = CovidTrackingProject(varargin)
            % Covid Tracking Project had a number of APIs including the last two that return 
            % the total numbers for USA and for each state. They're a little 
            % redundant with the larger queries, but I've included them here
            % anyway for the sake of completeness
            url = struct(...
                'nation', 'https://covidtracking.com/api/us/daily',...
                'states', 'https://covidtracking.com/api/states/daily',...
                'nation_current', 'https://covidtracking.com/api/us',...
                'states_current', 'https://covidtracking.com/api/states');
            
            obj@DataSource(url, varargin{:});
            obj.update();
        end

        function update(obj)
            [obj.stateData, obj.nationData] = obj.getData();
        end

        function cacheData(obj)
            websave([obj.DATA_DIR, 'ctp-states.json'], obj.URL.states);
            fprintf('\tCovidTrackingProject: Saved to %s\n',... 
                [obj.DATA_DIR, 'ctp-states.json']);
            websave([obj.DATA_DIR, 'ctp-nation.json'], obj.URL.states);
            fprintf('\tCovidTrackingProject: Saved to %s\n',... 
                [obj.DATA_DIR, 'ctp-nation.json']);
        end
    end

    % Additional dataset-specific functions
    methods
        function T = getDataByState(obj, stateName)
            % GETDATABYSTATE  Pulls one state from `stateData`
            T = obj.stateData(strcmpi(obj.stateData.state, stateName), :);
            if isempty(T)
                warning('%s not found. Use state two-letter abbreviations', stateName);
            end
        end

        function T = getDataByDay(obj, dateName)
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
            T = obj.stateData(obj.stateData.date == dateInput, :);
        end

        function data = getNationTotal(obj)
            % GETNATIONTOTAL  Returns current cumulative data for USA
            importedData = webread(obj.URL.nation_current, obj.getWebOptions());
            data = importedData{1};
            
            % Different format from usa-daily and states ISO 8601 times...
            data.lastModified = datestr(datenum8601(data.lastModified));
        end

        function data = getStatesTotal(obj)
            % GETSTATESTOTAL  Returns cumulative data for each state
            importedData = webread(obj.URL.states_current, obj.getWebOptions());
            missingFields = setdiff(fieldnames(importedData{1}),... 
                fieldnames(importedData{end}));

            data = importedData;  
            for i = numel(data)-3:numel(data)
                for j = 1:numel(missingFields)
                    data{i}.(missingFields{j}) = NaN;
                end
            end
            data = struct2table(cat(1, data{:}));

            data = obj.fixImportedData(data);
        end
    end
    
    methods (Access = protected)
        function [importedStateData, importedNationData] = importData(obj)
            if obj.useCache
                importedNationData = obj.loadIfExists([obj.DATA_DIR, 'ctp-nation.json']);
                importedStateData = obj.loadIfExists([obj.DATA_DIR, 'ctp-states.json']);
            else
                importedNationData = webread(obj.URL.nation, obj.getWebOptions());
                importedStateData = webread(obj.URL.states, obj.getWebOptions());
            end
        end

        function [states, nation] = getData(obj)   
            [importedStateData, importedNationData] = obj.importData();
            % As mentioned below, the post-processing of Covid Tracking
            % Project's data was pretty involved, so I moved it into
            % separate functions rather than pasting it all into getData.
            fprintf('\tParsing national data...\n')
            nation = obj.parseAmericaDaily(importedNationData);
            fprintf('\tParsing state data...\n');
            states = obj.parseStatesDaily(importedStateData);
        end
    end

    % Covid Tracking Project's data required a significant amount of
    % post-processing so there are a few extra functions to handle that.
    % More about this can be seen in the tutorial.
    methods (Access = private)
        function T = parseAmericaDaily(obj, importedData)
            % PARSEAMERICADAILY  Current USA data
            T = struct2table(cat(1, importedData{:}));

            T = obj.fixImportedData(T);
        end

        function T = parseStatesDaily(obj, importedData)
            % Daily data for each state, DC and territory
            data = importedData;
            maxFieldNames = fieldnames(data{1});
            maxFields = numel(maxFieldNames);

            for i = 1:numel(data)
                if numel(fieldnames(data{i})) ~= maxFields
                    missingFields = setdiff(maxFieldNames, fieldnames(data{i}));
                    for j = 1:numel(missingFields)
                        data{i}.(missingFields{j}) = NaN;
                    end
                end
            end

            T = struct2table(cat(1, data{:}));
            T = obj.fixImportedData(T);
        end

        function T = fixImportedData(obj, T)
            % FIXIMPORTEDDATA  Clean up and standardize imported data
            easternTimeHeaders = {'checkTimeEt', 'lastUpdateEt'};
            numericTimeHeaders = 'date';
            utcTimeHeaders = {'dateModified', 'dateChecked', 'lastModified'};
            charHeaders = {'state', 'fips', 'hash'};
            
            params = T.Properties.VariableNames;

            % This isn't the most efficient approach but our datasets have
            % a small number of parameters so the time cost is negligable
            % and we avoid hard-coding any specific parameters
            for i = 1:numel(params)
                if ismember(params{i}, easternTimeHeaders)
                    T.(params{i}) = datetime(datestr(T.(params{i})));
                elseif ismember(params{i}, numericTimeHeaders)
                    T.(params{i}) = datetime(num2str(T.(params{i})),... 
                        'InputFormat', 'yyyyMMdd');
                elseif ismember(params{i}, utcTimeHeaders)
                    T.(params{i}) = datetime(T.(params{i}),... 
                        'InputFormat', 'uuuu-MM-dd''T''HH:mm:ssXXX',... 
                        'TimeZone', 'UTC');
                elseif ismember(params{i}, charHeaders)
                    T.(params{i}) = string(T.(params{i}));
                elseif obj.isSemifull(T.(params{i}))
                    T.(params{i}) = semifullcells2doubles(T.(params{i}));
                end
            end
        end
    end
end