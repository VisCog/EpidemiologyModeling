% Tutorial One - parsing JSON API data COVID TRACKING PROJECT Information
% on their API: https://covidtracking.com/api

% Make sure to add covid19-data-import and subfolders to your path by
% editing the code below to reflect wherever you saved the repository
addpath(genpath('.../covid19-data-import'))

% Here I've written out my workflow for parsing the state-level data from
% the Covid Tracking Project to provide some insight into how I ended up
% writing the data scraping functions. Although this isn't all the data
% scraping we discussed in class (where you are reading info from an html 
% file), being able to parse the results of API's like Covid Tracking 
% Project's will take you pretty far. It also is the most applicable 
% approach to the datasets in the wiki currently).

% First I'm going to define some custom parameters that will be passed to
% MATLAB's webread function
opts = weboptions('Timeout', 120,...
    'ContentType', 'json',...
    'ContentReader', @loadjson);

% 1. Increasing the Timeout value (in seconds) can be useful for slow wifi
% connections - when queries fail, increasing Timeout is usually what
% MATLAB suggests doing first so I usually just set it high from the start.

% 2. Sometimes it's useful to tell MATLAB what content to expect so I 
% usually do it by default even if it's not necessary. All of the importing 
% done here will return .json data.

% 3. loadjson is an improved version of MATLAB's built-in JSON decoder, and
% is included in the 'lib' folder. It's part of JSONlab, a great toolbox
% that can be found on Github or MATLAB's FileExchange For more info, see:
% https://github.com/fangq/jsonlab

%% USA data (single entry per field)
% You want to read the data from this URL into MATLAB:
url = 'https://covidtracking.com/api/us';
importedData = webread(url, opts);
% It's a structure inside a cell, so make it a structure. Especially when
% testing something new, I like to reserve "importedData" for the output of
% webread and create a new variable (like "data") to work with directly.
data = importedData{1};
disp(data)
% Not bad! It's basically ready to work with, although you might want to
% convert the time into MATLAB's format.
data.dateModified = datestr(datenum8601(data.dateModified));

% -------------------------------------------------------------------------
%% State-level data (multiple entries per field)
% Here's where it gets harder. Fortunately the state-level data provides a
% good overview of some of the issues you may run into when importing data
% from an API into MATLAB so I'll go through it in detail.
url = 'https://covidtracking.com/api/states';
% You could actually go to this URL and see the data returned in your
% browser, although it's hard to read in the raw format. I like to enable a
% Google Chrome extension called "JSON Formatter" that automatically
% formats and color-codes JSON files.

% Import the data using "webread".
importedData = webread(url, opts);

%% Initial parsing of imported data
% The imported data is 50 cells (one corresponding to each state) each
% containing a structure of the state's data
importedData{1}  % Here's Alaska's data

% Here's the data that you'll get for each state
fieldnames(importedData{1})

% Concatenate the structures, then make them into a table
data = struct2table(cat(1, importedData{:}));
% Unfortunately, this returns an error! Usually the fieldnames in each
% structure are identical, so you can just concatenate them. Here the error
% information says the fieldnames are not all the same :(


% You could look inside each cell to figure out what's going on, but that
% isn't very efficient. I tried a for-loop to report the total number of
% fields in each cell
for i = 1:numel(data)
    fprintf('%s - %u fields\n', importedData{i}.state,... 
        numel(fieldnames(importedData{i})));
end
% The last four fields are missing a series of scores and grades.
missingFields = setdiff(fieldnames(importedData{1}), fieldnames(importedData{end}))

% There's a few ways to deal with this situation, depending on your goals.

% 1. You could just ignore those areas. Maybe you only cared about the
% states and planned to remove DC and the territories anyway.
data = cat(1, importedData{1:end-4});
% Returns a 52x1 struct array

% 2. You could just add those fields to the last four to appease MATLAB...
data = importedData;  % Keep "importedData" as the unaltered return
for i = numel(data)-3:numel(data)
    for j = 1:numel(missingFields)
        data{i}.(missingFields{j}) = NaN;
    end
end
data = struct2table(cat(1, data{:}))

%% Tables
% Either way, now you have a data table! It's a similar idea to Python's
% pandas data frames.
openvar('data')  % An Excel-like visualization of the data table

% To learn more about how to work with data in a MATLAB table, check out 
% the examples MATLAB provides:
% https://www.mathworks.com/help/matlab/tables.html

%% Cleaning up the data table
% If the imported data for a single parameter (like "hospitalized")
% contained a combination of integers and "null" values, MATLAB imports the
% null values as empty. Combining the empty values and the integers into
% one column requires each individual value to be placed inside a cell.
data.hospitalized  % 56x1 cell array :(
% This will get very annoying when you want some of the integers and you
% have to pull them out of a cells and concatenate into an array each time.

% Passing all columns with this situation through semifullcells2doubles (in
% 'util' folder) will remedy this.
data.hospitalized = semifullcells2doubles(data.hospitalized);
data.hospitalizedCurrently = semifullcells2doubles(data.hospitalizedCurrently);
data.hospitalizedCumulative = semifullcells2doubles(data.hospitalizedCumulative);
data.pending = semifullcells2doubles(data.pending);
data.inIcuCumulative = semifullcells2doubles(data.inIcuCumulative);
data.inIcuCurrently = semifullcells2doubles(data.inIcuCurrently);
data.onVentilatorCurrently = semifullcells2doubles(data.onVentilatorCurrently);
data.onVentilatorCumulative = semifullcells2doubles(data.onVentilatorCumulative);
data.recovered = semifullcells2doubles(data.recovered);

% At this point, you now should begin to understand why MATLAB really isn't
% the best language for this sort of thing...

% Convert time columns into "datestr"
data.checkTimeEt = datestr(data.checkTimeEt);
data.lastUpdateEt = datestr(data.lastUpdateEt);

% Convert ISO 8601 times into "datestr" using function from File Exchange
% that does not accept an array of inputs like datestr.
for i = 1:height(data)
    data.dateModified(i) = datestr(datenum8601(data.dateModified{i}));
    data.dateChecked(i) = datestr(datenum8601(data.dateModified{i}));
end

% You may notice the "notes" field is always the same and requests that
% "totalTestResults" be used instead of "total". So we can delete "total"
% along with the "notes" column that takes up a lot of space
disp(data.notes)
data.notes = [];
data.total = [];
% It's good to know these will be deprecated so you don't make them an
% important part of your analyses. I skipped this in the final function 
% though so the code doesn't break when these fields get deprecated and 
% potentially disappear.

% Finally, the 'char' columns get put in individual cells which can be
% a pain if you want to get at one specific value:
T{1, 'state'}

% So I'm converting them to a column of strings, a data type Matlab rolled
% out in 2018 that's basically 'char' but easier to use in some cases
T.state = string(T.state);
T.fips = string(T.fips);
T.hash = string(T.hash);