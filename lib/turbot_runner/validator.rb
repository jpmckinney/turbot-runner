require 'active_support/core_ext/hash/slice'
require 'active_support/core_ext/object/to_query'

module TurbotRunner
  module Validator
    extend self

    def validate(data_type, record, identifying_fields, seen_uids, schema_path=nil)
      schema_path ||= TurbotRunner.schema_path(data_type)
      error = Openc::JsonSchema.validate(schema_path, record)

      if error
        return error[:message]
      end

      identifying_hash = identifying_hash(record, identifying_fields)
      if identifying_hash.nil?
        return 'The value of an identifying field may not be a hash'
      end

      identifying_attributes = identifying_hash.reject {|k, v| v.nil? || v == ''}
      if identifying_attributes.empty?
        return "There were no values provided for any of the identifying fields: #{identifying_fields.join(', ')}"
      end

      if !seen_uids.nil?
        record_uid = record_uid(identifying_hash)
        if seen_uids.include?(record_uid)
          return "Already seen record with these identifying fields: #{identifying_hash}"
        else
          seen_uids.add(record_uid)
        end
      end

      nil
    end

    def identifying_hash(record, identifying_fields)
      flattened = TurbotRunner::Utils.flatten(record)
      flattened.each do |k, v|
        identifying_fields.each do |field|
          return nil if k.start_with?("#{field}.")
        end
      end
      flattened.slice(*identifying_fields)
    end

    def record_uid(identifying_hash)
      Digest::SHA1.hexdigest(identifying_hash.to_query)
    end
  end
end
