# frozen_string_literal: true

module IdempotencyCheck
  # Snapshots full row content per table, so two snapshots can be compared to
  # catch changes that don't alter row counts (e.g. a counter being incremented).
  #
  # Only the tables the checked block wrote to are read — see SqlTracker.
  class RowSnapshot
    class << self
      def take(tables:, ignore_columns: [])
        connection = ActiveRecord::Base.connection

        tables.to_h do |table|
          [table, fetch_rows(connection, table, ignore_columns)]
        end
      end

      private

      def fetch_rows(connection, table, ignore_columns)
        order_columns = Array(connection.primary_key(table))
        sql = "SELECT * FROM #{connection.quote_table_name(table)}"
        sql << " ORDER BY #{order_columns.map { |c| connection.quote_column_name(c) }.join(', ')}" if order_columns.any?

        rows = connection.select_all(sql).map { |row| row.except(*ignore_columns) }
        # Tables without a usable primary key (e.g. composite/no-PK join
        # tables) have no natural row order from the DB — sort the result
        # ourselves so two snapshots taken back-to-back compare reliably.
        order_columns.any? ? rows : rows.sort_by(&:to_s)
      end
    end
  end
end
