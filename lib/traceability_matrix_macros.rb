require 'redmine'
require 'application_helper'



module TraceabilityMatrixMacros
  
  ##############################################################################
  
  Redmine::WikiFormatting::Macros.register do
    error_message_m1 = "Traceability matrix between two list of issues, as a simple cross reference table.\n\n" +
         "+Syntax:+\n" +
         "<pre>{{traceability_matrix_short(issue_query_id_row,issue_query_id_col,[options])}}</pre>\n\n" +
         "+Parameters+\n" +
         "* _issue_query_id_row_ : id of the issue query to get the list of issues to rows \n" +
         "* _issue_query_id_col_ : id of the issue query to get the list of issues to cols \n\n" +
         "+Options:+\n" +
         "* -p = project_id : Restrict explicitly to project. The parameter project_id can be either id number or name.\n" +
         "* -w = number : Specifies the width of the tables, in number of columns. The traceability matrix may be split into several tables.\n" +
         "* -i : Displays the ID of issues in both columns.\n" +
         "* -t : Displays the text subject of issue in columns and rows.\n" +
         "* -tc : Displays the text subject of issue in columns.\n" +
         "* -tr : Displays the text subject of issue in rows.\n" +
         "* -d : Displays the text description of issue in row.\n" +
         "* cf_xx : Display the custom field with number xx.\n" +
         "* -ir : Displays the ID of issues in rows 1.\n" +
         "* -ic : Displays the ID of issues in columns.\n" +
         "* -s : Displays the status of issues in rows and columns.\n" +
         "* -sr : Displays the status of issues in rows.\n" +
         "* -sc : Displays the status of issues in columns.\n\n" +
         "+Examples:+\n" +
         "<pre>{{traceability_matrix_short(1,2)}} ->  Show the matrix using issue queries with id 1 and 2\n" +
         "{{traceability_matrix_short(20,144,-w=20)}} Show the matrix, split into tables that contains 20 columns\n" +
         "{{traceability_matrix_short(20,144,-s)}} Each issue, in rows and columns displays its status\n</pre>\n"

    desc error_message_m1

    macro :traceability_matrix_short do |obj, args|
    
      ## Gestion des arguments ##      
      if args.empty?
        return textilizable(error_message_m1)
      else
        if Query.find_by_id(args[0].strip) == nil
          return 'Error : Unknown query id for rows'
        else
          query_row_id = Query.find(args[0].strip)     
        end
        if Query.find_by_id(args[1].strip) == nil
          return 'Error : Unknown query id for columns'
        else
          query_col_id = Query.find(args[1].strip) 
        end
      end
      
      # default values
      split_nb_cols = 20
      show_subject_row = false;
      show_subject_col = false;
      option_display_description = false;
      
      option_display_status_row = false
      option_display_status_col = false
      option_display_id_row = false
      option_display_id_col = false
      custom_field_id = 0
      project = nil
      
      args[2..-1].each do |arg|
        case arg
        when /^-d/
          # display description of issues
          option_display_description = true
        when /^-w/
          # width of array, in number of columns
          split_nb_cols = arg.delete('-w=').strip
          puts "nb columns param = " + split_nb_cols
        when /-sr/
          # display status of issues
          option_display_status_row = true
          option_display_status_col = false
        when /-sc/
          # display status of issues
          option_display_status_row = false
          option_display_status_col = true
        when /-s/
          # display status of issues
          option_display_status_row = true
          option_display_status_col = true
        when /-ir/
          # display status of issues
          option_display_id_row = true
          option_display_id_col = false
        when /-ic/
          # display status of issues
          option_display_id_row = false
          option_display_id_col = true
        when /-i/
          # display status of issues
          option_display_id_row = true
          option_display_id_col = true
        when /^-tr/
          # show subject text of issues
          show_subject_row = true
          show_subject_col = false
        when /^-tc/
          # show subject text of issues
          show_subject_row = false
          show_subject_col = true
        when /^-t/
          # show subject text of issues
          show_subject_row = true
          show_subject_col = true
        when /^-p/
          project = Project.find(arg[3..arg.length-1])
        when /^cf_/
          custom_field_id = arg[3..arg.length-1].to_i
        else
          puts "sinon" + arg
        end
      end

      ## Execution du controlleur ##
      mt_ctrl = MtController.new
      
      mt_ctrl.init_macro_context(project)
      mt_ctrl.get_trackers(query_row_id, query_col_id)  
      mt_ctrl.build_list_of_issues
            
      disp = String.new
      disp << render(:partial => 'mt/mt_synthese',
                     :locals => {:issue_cols => mt_ctrl.issue_cols, :query_cols => mt_ctrl.query_cols,
                     :issue_rows => mt_ctrl.issue_rows, :query_rows => mt_ctrl.query_rows, :issue_pairs => mt_ctrl.issue_pairs,
                     :not_seen_issue_cols => mt_ctrl.not_seen_issue_cols, :split_nb_cols => split_nb_cols.to_i,
                     :show_subject_row => show_subject_row,
                     :show_subject_col => show_subject_col,
	            	     :option_display_description => option_display_description,
                     :option_display_id_row => option_display_id_row,
                     :option_display_id_col => option_display_id_col,
                     :option_display_status_row => option_display_status_row,
                     :option_display_status_col => option_display_status_col,
                     :custom_field_id => custom_field_id})
      
      return disp.html_safe

    end # Fin macro


    error_message_m2 = "Detailed traceability matrix between two list of issues.\n\n" +
         "+Syntax:+\n" +
         "<pre>{{traceability_matrix_detailed(issue_query_id_col1,issue_query_id_col2,[options])}}</pre>\n\n" +
         "+Parameters+\n" +
         "* _issue_query_id_col1_ : id of the issue query to get the list of issues to column 1 \n" +
         "* _issue_query_id_col2_ : id of the issue query to get the list of issues to column 2 \n\n" +
         "+Options:+\n" +
         "* -p = project_id : Restrict explicitly to project. The parameter project_id can be either id number or name.\n" +
         "* -d : Displays the description of issues in both columns.\n" +
         "* -d1 : Displays the description of issues in column 1.\n" +
         "* -d2 : Displays the description of issues in column 2.\n" +
         "* -i : Displays the ID of issues in both columns.\n" +
         "* -i1 : Displays the ID of issues in column 1.\n" +
         "* -i2 : Displays the ID of issues in column 2.\n" +
         "* -s : Displays the status of issues in both columns.\n" +
         "* -s1 : Displays the status of issues in column 1.\n" +
         "* -s2 : Displays the status of issues in column 2.\n" +
         "* -n : accepts also query names for the first two parameters\n" +
         "* -h : Displays subheaders of each tracker column\n" +
         "* -t [version]: displays test results of last test execution (or specified version),\n" +
         "*               if redmine_redcase plugin is installed and used\n" +
         "* -c : color code cells of test cases to see not passed immediately\n\n" +
         "+Examples:+\n" +
         "<pre>{{traceability_matrix_detailed(1,2)}} ->  Show the matrix using issue queries with id 1 and 2\n" +
         "{{traceability_matrix_detailed(20,144,-d)}} Show the matrix, with description of issues\n</pre>\n" +
         "{{traceability_matrix_detailed(Requirements,Test Case, -n, -d, -h, -t 1.0)}} Show the matrix, with description of issues\n</pre>\n"

    desc error_message_m2

    macro :traceability_matrix_detailed do |obj, args|
    
      ## Gestion des arguments ##      
      if args.empty?
        return textilizable(error_message_m2)
      end

      settings = Setting['plugin_traceability_matrix']
      set_colors = {}
      set_colors['error_color'] = settings['error_color']
      set_colors['missing_color'] = settings['missing_color']
      set_colors['passed_color'] = settings['passed_color']
      default_options = settings['default_options'].split(',').collect{|x| x.strip || x}
      test_date_format = settings['test_date_format']

      allow_query_name = 0
      use_redcase_data = 0
      use_version = ""
      use_subheaders = false
      use_colors = false
      option_display_description_col1 = false
      option_display_description_col2 = false
      option_display_status_col1 = false
      option_display_status_col2 = false
      option_display_id_col1 = false
      option_display_id_col2 = false
      project = nil

      options = args[2..-1] + default_options

      options.each do |arg|
        case arg
          when /-n/
            allow_query_name = 1
          when /-t/
            use_redcase_data = 1
            res = arg.scan(/-t (.+)/)
            if not res.empty?
              use_version = res[0][0]
            end
          when /-h/
            use_subheaders = true
          when /-c/
            use_colors = true
          when /-d1/
            # display description of issues
            option_display_description_col1 = true
            option_display_description_col2 = false
          when /-d2/
            # display description of issues
            option_display_description_col1 = false
            option_display_description_col2 = true
          when /-d/
            # display description of issues
            option_display_description_col1 = true
            option_display_description_col2 = true
          when /-s1/
            # display status of issues
            option_display_status_col1 = true
            option_display_status_col2 = false
          when /-s2/
            # display status of issues
            option_display_status_col1 = false
            option_display_status_col2 = true
          when /-s/
            # display status of issues
            option_display_status_col1 = true
            option_display_status_col2 = true
          when /-i1/
            # display status of issues
            option_display_id_col1 = true
            option_display_id_col2 = false
          when /-i2/
            # display status of issues
            option_display_id_col1 = false
            option_display_id_col2 = true
          when /-i/
            # display status of issues
            option_display_id_col1 = true
            option_display_id_col2 = true
          when /^-p/
            project = Project.find(arg[3..arg.length-1])
          else
            puts "sinon" + arg
        end
      end

      arg_0 = args[0].strip
      arg_1 = args[1].strip

      if (allow_query_name == 1) && (Query.find_by(name: arg_0) != nil)
        query_0 = Query.find_by name: arg_0
        query_col1_id = query_0.id
      elsif Query.find_by_id(arg_0) != nil
        query_col1_id = Query.find(arg_0)
      else
        return "Error : Unknown query id/name for column 1 - >#{arg_0}"
      end

      if (allow_query_name == 1) && (Query.find_by(name: arg_1) != nil)
        query_1 = Query.find_by name: arg_1
        query_col2_id = query_1.id
      elsif Query.find(arg_1) != nil
        query_col2_id = Query.find(arg_1)
      else
        return "Error: Unknwon query id/name for column 2- >#{arg_1}<"
      end

      ## Execution du controlleur ##
      mt_ctrl = MtController.new
      
      mt_ctrl.init_macro_context(project, use_redcase_data, use_colors,
                                 use_version, test_date_format)
      mt_ctrl.get_trackers(query_col1_id, query_col2_id)
      mt_ctrl.build_list_of_issues

      ## estimate col_span values ##
      # add one for subject, as this is always used
      col1_span = 1
      col2_span = 1

      subheaders = {}

      if use_subheaders
        subheaders['col1'] = []
        subheaders['col2'] = []

        if option_display_id_col1
          col1_span += 1
          subheaders['col1'] << l(:column_name_id)
        end
        if option_display_status_col1
          col1_span += 1
          subheaders['col1'] << l(:column_name_status)
        end
        subheaders['col1'] << l(:column_name_subject)
        if option_display_description_col1
          col1_span += 1
          subheaders['col1'] << l(:column_name_description)
        end

        col2_span += mt_ctrl.col2_span
        if option_display_id_col2
          col2_span += 1
          subheaders['col2'] <<  l(:column_name_id)
        end
        if option_display_status_col2
          col2_span += 1
          subheaders['col2'] <<  l(:column_name_status)
        end
        subheaders['col2'] << l(:column_name_subject)
        if option_display_description_col2
          col2_span += 2
          subheaders['col2'] << l(:column_name_description)
        end
        if mt_ctrl.col2_span > 0
          subheaders['col2'] << l(:column_name_testrun)
          subheaders['col2'] << l(:column_name_version)
          subheaders['col2'] << l(:column_name_result)
        end
      end

      disp = String.new
      disp << render(:partial => 'mt/mt_details', :locals => {
                     :issue_cols => mt_ctrl.issue_cols, :query_cols => mt_ctrl.query_cols,
                     :issue_rows => mt_ctrl.issue_rows, :query_rows => mt_ctrl.query_rows,
                     :issue_pairs => mt_ctrl.issue_pairs,
                     :use_subheaders => use_subheaders, :subheaders => subheaders,
                     :col1_span => col1_span, :col2_span => col2_span,
                     :not_seen_issue_cols => mt_ctrl.not_seen_issue_cols,
                     :option_display_id_col1 => option_display_id_col1,
                     :option_display_id_col2 => option_display_id_col2,
                     :option_display_status_col1 => option_display_status_col1,
                     :option_display_status_col2 => option_display_status_col2,
                     :option_display_description_col1 => option_display_description_col1,
                     :option_display_description_col2 => option_display_description_col2,
                     :colors => set_colors})
      return disp.html_safe

    end # Fin macro
        
  end

end

################################################################################
