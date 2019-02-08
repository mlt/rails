# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module PostgreSQL
      module ReferentialIntegrity # :nodoc:
        def disable_referential_integrity # :nodoc:
          original_exception = nil

          begin
            transaction(requires_new: true) do
              execute(tables_with_schema_all.collect { |name| "ALTER TABLE #{name} DISABLE TRIGGER ALL" }.join(";"))
            end
          rescue ActiveRecord::ActiveRecordError => e
            original_exception = e
          end

          begin
            yield
          rescue ActiveRecord::InvalidForeignKey => e
            warn <<-WARNING
WARNING: Rails was not able to disable referential integrity.

This is most likely caused due to missing permissions.
Rails needs superuser privileges to disable referential integrity.

    cause: #{original_exception.try(:message)}

              WARNING
            raise e
          end

          begin
            transaction(requires_new: true) do
              execute(tables_with_schema_all.collect { |name| "ALTER TABLE #{name} ENABLE TRIGGER ALL" }.join(";"))
            end
          rescue ActiveRecord::ActiveRecordError
          end
        end
      end
    end
  end
end
