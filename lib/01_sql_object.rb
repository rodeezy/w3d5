require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    @columns ||= (
    DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        "#{self::table_name}"
    SQL
    .first.map { |e| e.to_sym  }
      )
    @columns
    # ...
  end

  def self.finalize!
    self.columns.each do |column|
      define_method("#{column}") {self.attributes[column]}
      define_method("#{column}=") do |el|
        self.attributes[column] = el
      end
    end
  end

  def self.table_name=(table_name)
    # ...
    @table_name = table_name
  end

  def self.table_name
    @table_name||self.to_s.tableize
    # ...
  end

  def self.all
    self::parse_all(
    DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        "#{self::table_name}"
    SQL
      )
    # ...
  end

  def self.parse_all(results)
    #drop 1 bc first row is just the column names
    #i think ternary avoidable when using execute instead...
    #... of execute2 in self.all
    list = results.drop((results.first.is_a?(Array) ? 1 : 0))
    list.map { |e| self.new(e) }
    # ...
  end

  def self.find(id)
    a =
    DBConnection.execute2(<<-SQL, id)
      SELECT
        *
      FROM
        "#{self::table_name}"
      WHERE
        id = ?
    SQL
    return nil if a.length == 1
    self.new(a.last)
    # ...
  end

  def initialize(params = {})
    # ...
    params.each do |attr_name, value|
      att = attr_name.to_sym
      raise "unknown attribute '#{attr_name}'" unless self.class::columns.include? att
      send "#{att}=", value
    end
  end

  def attributes
    @attributes ||= {}
    @attributes
    # ...
  end

  def attribute_values
    self.class::columns.map { |e| self.send e  }
    # ...
  end

  def attr_vals_id_at_end
    result = []
    attributes.each do |k,v|
      result << v unless k == :id
    end
    result << attributes[:id]
  end

  def insert
    attributes[:id] ||= self.class.all.length + 1
    col_names = self.class::columns.join(',')
    question_marks = ["?"] * self.class::columns.length
    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class::table_name} (#{col_names})
      VALUES
        (#{question_marks.join(',')});
    SQL
    # ...
  end

  def set_line
    result = ""
    self.class.columns.drop(1).each do |col|
      result += "#{col} = ?, "
    end
    result[0..-3]
  end

  def update

    DBConnection.execute(<<-SQL, *attr_vals_id_at_end)
      UPDATE
        #{self.class::table_name}
      SET
        #{set_line}
      WHERE
        id = ?
    SQL
    # ...
  end

  def save
    id.nil? ? insert : update
    # ...
  end
end
