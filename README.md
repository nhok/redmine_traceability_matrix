# traceability_matrix

## Purpose 

Shows the traceability matrix of 2 lists (query) of issues. If some relations exists between issues (either related_to, blocked_by, followed...) they will appear in the matrix.
The macro uses custom queries to get the two lists of issues.
The traceability matrix is available in wiki pages, accessible with 2 macros :

traceability_matrix_short : is a cross table

traceability_matrix_detailed : is a 2 column table, that put related issues side by side.

![Image of output](https://github.com/nhok/redmine_traceability_matrix/blob/master/screen_shots/screen_shot.png)

This plugin has been inspired by the Traceability plugin written by Emergya Consultoria.

## Configuration of the plugin

The plugin has a configuration page, found under Administration/Plugins

![Image of output](https://github.com/nhok/redmine_traceability_matrix/blob/master/screen_shots/plugin_configure.png)

After selecting link "Configure" the configuration page of the plugin will be shown

![Image of output](https://github.com/nhok/redmine_traceability_matrix/blob/master/screen_shots/configure.png)

In the first field, you can configure options, which will always be added to the macro 
traceability_matrix_detailed call, so you won't have to specify the options in the wiki macro. 

The second field is used to specify the date format of the "test run" column of the 
traceability_matrix_detailed macro (this column will be added with the -t option). As formatters are
all symbols valid, which are used in the ruby time/date formatting.

The next three field specify the color, certain cells will be formatted with, if the macro 
traceability_matrix_detailed shows test cases. The colors could be specified as standard html color names.


## traceability_matrix_detailed

The traceability_matrix_detailed has several options:

![Image of output](https://github.com/nhok/redmine_traceability_matrix/blob/master/screen_shots/detailed_table_macro_help_text.png)

In the following there are some samples to demonstrate the impact of the available options :

![Image of output](https://github.com/nhok/redmine_traceability_matrix/blob/master/screen_shots/detailed_table_simple.png)

![Image of output](https://github.com/nhok/redmine_traceability_matrix/blob/master/screen_shots/detailed_table_tests.png)

![Image of output](https://github.com/nhok/redmine_traceability_matrix/blob/master/screen_shots/detailed_table_header_tests.png)

![Image of output](https://github.com/nhok/redmine_traceability_matrix/blob/master/screen_shots/detailed_table_header_colored_tests.png)
