% DEMO
% How to access the imported data for each source and a few small examples
% for how the data could then be used.

% ------------------------------------------------------------------------
%% European CDC datset
% ------------------------------------------------------------------------
ecdc = EuroCDC();

% View dataset
T = ecdc.data;
openvar('T');

% Each class has the same function for caching data
ecdc.cacheData();
% If you check the data folder, you will see 'european_countries.json'
% You can now instantiate the EuroCDC class w/out wifi
ecdc = EuroCDC(true);  % True loads from cache. Default is false

% In addition to the data parsing, I included a function to return just the
% data for one specific country
T = ecdc.getDataByCountry('canada');
openvar('T');

% At this point, it's up to you to decide what to do with the data. 
% For example:
ax = axes('Parent', figure());
hold(ax, 'on');
plot(ax, T.dateRep, T.cases, 'b', 'LineWidth', 1.5);
plot(ax, T.dateRep, T.deaths, 'r', 'LineWidth', 1.5);
set(ax, 'YScale', 'log');
grid(ax, 'on');
legend(ax, {'cases', 'deaths'},...
    'Location', 'northwest', 'FontSize', 12);
title(ax, 'Canada');

% ------------------------------------------------------------------------
%% CovidTrackingProject
% ------------------------------------------------------------------------
% This is the most complicated dataset as there were multiple endpoints 
% with distinct datasets
ctp = CovidTrackingProject();
% The main datasets are: 
%% 1. US statistics per day:
T = ctp.nationData;
openvar('T');

ax_hospitalizations = axes('Parent', figure(), 'YScale', 'log');
hold(ax_hospitalizations, 'on');
plot(ax_hospitalizations, T.date, T.hospitalizedCumulative, '-o',... 
    'Color', [0, 0, 0.4], 'LineWidth', 1.5,...
    'DisplayName', 'USA');
grid(ax_hospitalizations, 'on');
title(ax_hospitalizations, 'Cumulative Hospitalizations')
ylabel(ax_hospitalizations, 'Number of people');

%% 2. state-level statistics per day:
T = ctp.stateData;
openvar('T');

% I included a function to access just the data for one state:
T = ctp.getDataByState('NY');

% For example, add hospitalizations for New York State to previous graph
plot(ax_hospitalizations, T.date, T.hospitalizedCumulative,... 
    '-ob', 'LineWidth', 1.5,...
    'DisplayName', 'New York');
legend(ax_hospitalizations, 'FontSize', 11, 'Location', 'northwest');

%
% In addition, there were endpoints to query the current total numbers for
% the USA and at the state-level. This was a little redundant so it's not 
% saved as a distinct data property, however, I did include functions for 
% accessing this data anyway:
%% Current data for USA
S = ctp.getNationTotal();
% Print the dataset to cmd line for inspection...
disp(S)
% Get some relevant numbers
fprintf('%u cases, %u hospitalizations and %u deaths\n',...
    S.positive, S.hospitalizedCumulative, S.death);

% Plot testing numbers
figure()
pie([S.positive, S.negative, S.pending]);
legend({'Positive', 'Negative', 'Pending'},...
    'Location', 'southoutside', 'EdgeColor', 'none',...
    'Orientation', 'horizontal');
title('COVID-19 Testing in the USA');

%% Current state-level data
T = ctp.getStatesTotal();
openvar('T');

% Examples:
% Which states don't have any data for currently hospitalized #s?
disp(T{isnan(T.hospitalizedCurrently), 'state'})

% For example, which state has the most people currently hospitalized?
[val, ind] = max(T.hospitalizedCurrently);
fprintf('%s has %u people hospitalized\n', T{ind, 'state'}, val);

% Which state (or territory) has the least people hospitalized?
[val, ind] = min(T.hospitalizedCurrently);
fprintf('%s has %u people hospitalized\n', T{ind, 'state'}, val);

% ------------------------------------------------------------------------
%% Citymapper - City Mobility Index (CMI)
% ------------------------------------------------------------------------
% Instantiate the Citymapper class
ctm = Citymapper();

% Check out the data
T = ctm.data;
openvar('T');

% To check which cities are listed
ctm.getCities()

% Plot CMI in a few American cities
americanCities = {'Boston', 'Chicago', 'LosAngeles', 'NewYorkCity',... 
    'Philadelphia', 'SanFrancisco', 'Seattle', 'WashingtonDC'};

% Alternative to MATLAB's default color order
colorList = othercolor('Spectral8', numel(americanCities));

ax_usa_cmi = axes('Parent', figure('Name', 'American CMI'));
hold(ax_usa_cmi, 'on');
for i = 1:numel(americanCities)
    % x100 to convert to % values
    plot(ax_usa_cmi, T.Date, 100 * T.(americanCities{i}),... 
        'Color', colorList(i, :), 'LineWidth', 1.5,...
        'DisplayName', americanCities{i});
end
ylabel(ax_usa_cmi, 'City Mobility Index');
legend(ax_usa_cmi, 'Location', 'northeast', 'FontSize', 14);
title(ax_usa_cmi, '% of American cities moving compared to usual')
grid(ax_usa_cmi, 'on');
ax_usa_cmi.XLim(2) = max(T.Date);

% Single city bar graph similar to those on Citymapper's website
ax_seattle_cmi = axes('Parent', figure('Name', 'Seattle CMI'));
% x100 to convert to % value
barHandle = bar(ax_seattle_cmi, T.Date, 100*T.Seattle);
ylabel(ax_seattle_cmi, 'City Mobility Index');
grid(ax_seattle_cmi, 'on');
title(ax_seattle_cmi, '% of Seattle moving compared to usual');

% The large amount of NaNs in the dataset throw off the x-axis limits and 
% I got tired of adjusting them manually, so I added in a function to 
% return the lowest and highest non-NaN dates.
set(ax_seattle_cmi, 'XLim', ctm.getCityDateRange('Seattle'), 'YLim', [0 120]);

% Add colormap
cMap = othercolor('RdYlGn8', 100);
ind = ceil(100*(T.Seattle/max(T.Seattle)));
cData = zeros(numel(ind), 3);
cData(~isnan(ind), :) = cMap(ind(~isnan(ind)), :);
set(barHandle, 'CData', cData, 'FaceColor', 'flat');