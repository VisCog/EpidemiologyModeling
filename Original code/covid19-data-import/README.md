### covid19-data-import
https://github.com/sarastokes/covid19-data-import

This repository is created as part of an epidemiology modeling seminar at the University of Washington (see the main repository at [VisCog/EpidemiologyModeling](https://github.com/VisCog/EpidemiologyModeling)). The goal here is to provide some useful utilities for accessing COVID-19 data while also covering general techniques for importing and parsing data with MATLAB.

I included classes for parsing the [datasets used in the course](https://github.com/VisCog/EpidemiologyModeling/wiki/Datasets) in the `src` folder and demos on how to use them. Briefly, `DataSource` is the parent class and defines a few properties and methods that all subclasses use for consistency. There's one subclass per data source (e.g. `CovidTrackingProject`, `EuroCDC`). I will continue to add datasets up through next week's class. Currently, I have support for the following datasets:
- [Covid Tracking Project](https://covidtracking.com/api)
- [European Center for Disease Prevention and Control](https://www.ecdc.europa.eu/en/geographical-distribution-2019-ncov-cases)
- [New York Times](https://www.nytimes.com/interactive/2020/us/coronavirus-us-cases.html)
- [Citymapper City Mobility Index](https://citymapper.com/cmi/)

I haven't altered the parameter names used by each source (see the [dataset descriptions](https://github.com/VisCog/EpidemiologyModeling/wiki/Datasets) in the wiki for a summary) so there is considerable variability. The data is stored in a property called `data`, except for CovidTrackingProject which supports multiple queries and has both `stateData` and `nationData`.

The tutorials get into the technical details of a workflow for importing data and generating a table resembling a pandas DataFrame. In general, MATLAB is really not the best language for this sort of thing, but you can get the job done if absolutely necessary. 

### Resources
The `\lib` folder includes some open-source 3rd party code:
- [JSONLab](https://github.com/fangq/jsonlab)
- `datenum8601` from the [ISO 8601 Date String to Serial Date Number](https://www.mathworks.com/matlabcentral/fileexchange/39389-iso-8601-date-string-to-serial-date-number) package 
- `othercolor` and `colorData.mat` from the [othercolor](https://www.mathworks.com/matlabcentral/fileexchange/30564-othercolor) package to mimic Citymapper's colormaps