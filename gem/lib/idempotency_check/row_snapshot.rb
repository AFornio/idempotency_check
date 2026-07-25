module IdempotencyCheck
  # Snapshots full row content per table, so two snapshots can be compared to
  # catch changes that don't alter row counts (e.g. a counter being incremented).
  class RowSnapshot
    def self.take(ignore_columns: [])
      connection = ActiveRecord::Base.connection

      connection.tables.each_with_object({}) do |table, rows|
        next if table == "schema_migrations" || table == "ar_internal_metadata"

        rows[table] = connection.select_all(
          "SELECT * FROM #{connection.quote_table_name(table)} ORDER BY id"
        ).map { |row| row.except(*ignore_columns) }
      end
    end
  end
end
