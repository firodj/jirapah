class Story < ApplicationRecord
  validates_presence_of :guid
  belongs_to :creator, class_name: Member.to_s, optional: true
  belongs_to :assignee, class_name: Member.to_s, optional: true
  belongs_to :reporter, class_name: Member.to_s, optional: true
  belongs_to :qa_tester, class_name: Member.to_s, optional: true
  belongs_to :pair_assignee, class_name: Member.to_s, optional: true
  has_many :change_logs
  has_many :comments
  attribute :labels, :json

  def done?
    internal_status == :done
  end

  def todo?
    internal_status == :todo
  end

  def inprogress?
    internal_status == :inprogress
  end

  def testing?
    internal_status == :testing
  end

  def ready?
    internal_status == :ready
  end

  def internal_status
    case status_guid
    when '10000', '10401', '10604'
      :todo
    when '10704', '13800'
      :inprogress
    when '11702'
      :testing
    when '12002'
      :ready
    when '12801'
      :done
    end
  end

  def tags
    parse_tags
    @tags
  end

  def clean_summary
    parse_tags
    @clean_summary
  end

  def assignee_names
    return @assignee_names unless @assignee_names.nil?
    names = []
    names.push(assignee.name) if assignee
    names.push(pair_assignee.name) if pair_assignee
    @assignee_names = names.uniq
  end

  private
    def parse_tags
      return unless @tags.nil? or @clean_summary.nil?
      tags = []
      @clean_summary = summary
        .gsub( /\[(.*?)\]/ ) { tags.push($1.strip); '' }
        .strip

      norm_labels = labels.map { |label| label.delete(" \t\r\n").downcase }
      @tags = tags.reject { |tag| norm_labels.include? tag.delete(" \t\r\n").downcase }
    end

end