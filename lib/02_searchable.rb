require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where_line(params)
    arr = []
    params.keys.each { |el| arr << "#{el} = ?"}
    arr.join(" AND ")
  end
  def where(params)
    # ...
    DBConnection.execute(<<-SQL, *params.values)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{where_line(params)}
    SQL
    .map { |e| self.new(e) }
  end
end

class SQLObject
  extend Searchable
  # Mixin Searchable here...
end
