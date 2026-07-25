module IdempotencyCheck
  # Snapshots row counts per table, so two snapshots can be compared to see
  # whether running something again changed the resulting state.
  class TableSnapshot
    def self.take
      connection = ActiveRecord::Base.connection

      connection.tables.each_with_object({}) do |table, counts|
        next if table == "schema_migrations" || table == "ar_internal_metadata"

        counts[table] = connection.select_value("SELECT COUNT(*) FROM #{connection.quote_table_name(table)}").to_i
      end
    end
  end
end
