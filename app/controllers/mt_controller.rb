class MtController < ApplicationController
  unloadable
 
  before_filter :find_project_by_project_id, :authorize, :get_trackers
  menu_item :traceability_matrix
  
  helper :issues
  helper :projects
  helper :queries
  include QueriesHelper
  helper :sort
  include SortHelper

  attr_accessor :issue_rows
  attr_accessor :issue_cols 
  attr_accessor :query_rows
  attr_accessor :query_cols
  attr_accessor :tracker_rows
  attr_accessor :tracker_cols
  attr_accessor :issue_pairs
  attr_accessor :not_seen_issue_cols
  attr_accessor :col2_span


  def init_macro_context(project, use_redcase_data, use_colors, use_version, test_date_format)
    @project = project
    @use_redcase_data = use_redcase_data
    @use_colors = use_colors
    @use_version = use_version
    @test_date_format = test_date_format
    @col2_span = 0
  end
  
  def build_list_of_issues 
    @issue_rows = @query_rows.issues().sort {|issue_a, issue_b| issue_a.id <=> issue_b.id}
    @issue_cols = @query_cols.issues().sort {|issue_a, issue_b| issue_a.id <=> issue_b.id}
    @issue_pairs = {}
    @not_seen_issue_cols = {}
    
    if @issue_rows.empty?
      return
    end
    
    if @issue_cols.empty?
      return
    end

    relations = IssueRelation.where("issue_from_id IN (:ids) OR issue_to_id IN (:ids)", :ids => @issue_rows.map(&:id)).all

    Issue.load_relations(@issue_cols)

    @not_seen_issue_cols = @issue_cols.dup
    relations.each do |relation|
      if @not_seen_issue_cols.include?relation.issue_to
        set_issue_pairs(relation.issue_from, relation.issue_to, relation.issue_to.id)
        @not_seen_issue_cols.delete relation.issue_to
      elsif @not_seen_issue_cols.include?relation.issue_from
        set_issue_pairs(relation.issue_to, relation.issue_from, relation.issue_to.id)
        @not_seen_issue_cols.delete relation.issue_from
      else
      end
    end

    relations = IssueRelation.where("issue_from_id IN (:ids) OR issue_to_id IN (:ids)", :ids => @issue_cols.map(&:id)).all

    issue_rows_copy = @issue_rows.dup
    relations.each do |relation|
      if issue_rows_copy.include?relation.issue_from
        set_issue_pairs(relation.issue_from, relation.issue_to, relation.issue_to.id)
        issue_rows_copy.delete relation.issue_to
      elsif issue_rows_copy.include?relation.issue_to
        set_issue_pairs(relation.issue_to, relation.issue_from, relation.issue_to.id)
        issue_rows_copy.delete relation.issue_from
      else
      end
    end

    return
  end

  def set_issue_pairs(first, second, issue_id)
    test_case = TestCase.find_by_issue_id(issue_id)

    @issue_pairs[first] ||= {}
    @issue_pairs[first][second] ||= {}

    if @use_redcase_data == 0
      @issue_pairs[first][second]['result'] = 'no_test_defined'
      @issue_pairs[first][second]['class'] = 'TestNotDefined'
    elsif test_case.nil?
      @issue_pairs[first][second]['result'] = 'no_test_defined'
      @issue_pairs[first][second]['class'] = 'TestNotDefined'
    else
      @col2_span = 3
      if @use_version.empty?
        journal_entry = ExecutionJournal.where("test_case_id = #{test_case.id}").order('created_on DESC')[0]

        if journal_entry.nil?
          @issue_pairs[first][second]['version'] = '---'
          @issue_pairs[first][second]['result'] = 'NotRun'
          @issue_pairs[first][second]['class'] = 'TestNotRun'
        else
          result = ExecutionResult.find_by_id(journal_entry.result_id)
          version = Version.find_by_id(journal_entry.version_id)
          environ = ExecutionEnvironment.find_by_id(journal_entry.environment_id)
          @issue_pairs[first][second]['class'] = "Test" + result.name.sub(" ","")
          @issue_pairs[first][second]['version'] = version.name
          @issue_pairs[first][second]['result'] = result.name
          @issue_pairs[first][second]['environ'] = environ.name
          @issue_pairs[first][second]['created'] = journal_entry.created_on.strftime(@test_date_format)
        end
      else
        version = Version.find_by_name(@use_version)
        journal_entry = ExecutionJournal.where("test_case_id = #{test_case.id} AND version_id = #{version.id}").order('created_on DESC')[0]

        if journal_entry.nil?
          @issue_pairs[first][second]['version'] = @use_version
          @issue_pairs[first][second]['result'] = 'NotRun'
          @issue_pairs[first][second]['class'] = 'TestNotRun'
        else
          result = ExecutionResult.find_by_id(journal_entry.result_id)
          environ = ExecutionEnvironment.find_by_id(journal_entry.environment_id)
          @issue_pairs[first][second]['class'] = "Test" + result.name.sub(" ","")
          @issue_pairs[first][second]['version'] = version.name
          @issue_pairs[first][second]['result'] = result.name
          @issue_pairs[first][second]['environ'] = environ.name
          @issue_pairs[first][second]['created'] = journal_entry.created_on.strftime(@test_date_format)
        end
      end
    end

    if @use_colors == false
        @issue_pairs[first][second]['class'] = "NoColor"
    end

  end

  def get_trackers(query_rows_id=Setting.plugin_traceability_matrix['tracker0'],
                   query_cols_id=Setting.plugin_traceability_matrix['tracker1'])
    @tracker_rows = nil
    @query_rows = IssueQuery.find_by_id(query_rows_id)
    if @project.nil?
      @query_rows.project = Project.find_by_id(@query_rows.project_id)
    else
      @query_rows.project = @project
    end
    @query_rows.filters.each do |name, options|
      if (name == "tracker_id")
        tracker_id = options[:values].first
         @tracker_rows = Tracker.find_by_id(tracker_id)
      end
    end

    # Grouped by category cause an error when getting the issues from the query
    if (@query_rows.group_by="category")
      @query_rows.group_by=""
    end

    @tracker_cols = nil
    @query_cols = IssueQuery.find_by_id(query_cols_id)
    if @project.nil?
      @query_cols.project = Project.find_by_id(@query_cols.project_id)
    else
      @query_cols.project = @project
    end
    @query_cols.filters.each do |name, options|
      if (name == "tracker_id")
        tracker_id_ = options[:values].first
         @tracker_cols = Tracker.find_by_id(tracker_id_)
      end
    end

    # Grouped by category cause an error when getting the issues from the query
    if (@query_cols.group_by="category")
      @query_cols.group_by=""
    end

  rescue ActiveRecord::RecordNotFound
    flash[:error] = l(:'traceability_matrix.setup')
    render
  end

  def show
    respond_to do |format|
      format.pdf do
        render :pdf => "file.pdf", :template => 'mt/_mt_details.html.erb'
      end
      format.html
    end
  end

end
