class Epic < ApplicationRecord
  belongs_to :story
  has_many :stories

  def clean_title
    return @clean_title unless @clean_title.nil?
    clean_title, tags = parse_tags(title)
    @clean_title = clean_title
  end

  private
    def parse_tags(text)
      tags = []
      clean_text = text
        .gsub( /\[(.*?)\]/ ) { tags.push($1.strip); '' }
        .strip
      [clean_text, tags]
    end

end
