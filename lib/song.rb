require_relative "../config/environment.rb"
require 'active_support/inflector'

class Song

  # depends on the `active_support/inflector` `#pluralize` method
  def self.table_name
    self.to_s.downcase.pluralize
  end

  # gets column data from the db using an internal sqlite method and iterates
  # through them to pull column names
  def self.column_names
    DB[:conn].results_as_hash = true

    sql = "pragma table_info('#{table_name}')"

    table_info = DB[:conn].execute(sql)
    column_names = []
    table_info.each do |row|
      column_names << row["name"]
    end
    column_names.compact
  end

  # sets attr_accessors for each column name, which will allow the #initialize method
  # to work
  self.column_names.each do |col_name|
    attr_accessor col_name.to_sym
  end

  # takes in a hash and iterates through to set each property (instantiated as an attr_accessor
  # above) to be equal to it's db value
  def initialize(options={})
    options.each do |property, value|
      self.send("#{property}=", value)
    end
  end

  # uses join methods to list every property and value in the correct order and formatting for
  # a sql insert statement. #table_name_for_insert is a custom method made only for this instance
  # and is equivalent to self.class.column_names.delete_if {|c| c == 'id'}.join(', ')
  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  # not necessary but makes the result look cleaner
  def table_name_for_insert
    self.class.table_name
  end

  # formats values for an easy sql insert statement
  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
      values << "'#{send(col_name)}'" unless send(col_name).nil?
    end
    values.join(", ")
  end

  # prevents potential mishaps with reassigning the primary key value
  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end

end
