class JsonType < ActiveRecord::Type::Value
  def cast(value)
    JSON.parse(value)
  end

  def serialize(value)
    JSON.dump(value)
  end
end