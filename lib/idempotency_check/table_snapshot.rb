# frozen_string_literal: true

module IdempotencyCheck
  # Snapshots row counts per table, so two snapshots can be compared to see
  # whether running something again changed the resulting state.
  #
  # `tables` is the set of tables the checked block actually wrote to — see
  # SqlTracker. Snapshotting only those keeps a check proportional to what
  # the job touches instead of to the size of the whole schema.
  class TableSnapshot
    class << self
      def take(tables:)
        connection = ActiveRecord::Base.connection

        tables.each_with_object({}) do |table, counts|
          counts[table] = connection.select_value(
            "SELECT COUNT(*) FROM #{connection.quote_table_name(table)}"
          ).to_i
        end
      end
    end
  end
end
