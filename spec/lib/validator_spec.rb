require 'spec_helper'

describe TurbotRunner::Validator do
  describe '.validate' do
    specify 'with valid record' do
      record = {
        'sample_date' => '2014-06-01',
        'source_url' => 'http://example.com/123',
        'number' => 123
      }
      expect(record).to be_valid
    end

    specify 'with record missing required field' do
      record = {
        'sample_date' => '2014-06-01',
        'number' => 123
      }
      expected_error = 'Missing required property: source_url'
      expect(record).to fail_validation_with(expected_error)
    end

    specify 'with record missing all identifying fields' do
      record = {
        'sample_date' => '2014-06-01',
        'source_url' => 'http://example.com/123'
      }
      expected_error = 'There were no values provided for any of the identifying fields: number'
      expect(record).to fail_validation_with(expected_error)
    end

    specify 'with record with empty sample_date' do
      record = {
        'sample_date' => '',
        'source_url' => 'http://example.com/123',
        'number' => 123
      }
      expected_error = 'Property not of expected format: sample_date (must be of format yyyy-mm-dd)'
      expect(record).to fail_validation_with(expected_error)
    end

    specify 'with record with invalid sample_date' do
      record = {
        'sample_date' => '2014-06-00',
        'source_url' => 'http://example.com/123',
        'number' => 123
      }
      expected_error = 'Property not of expected format: sample_date (must be of format yyyy-mm-dd)'
      expect(record).to fail_validation_with(expected_error)
    end

    context 'with nested identifying fields' do
      specify 'with record missing all identifying fields' do
        record = {
          'sample_date' => '2014-06-01',
          'source_url' => 'http://example.com/123',
          'one' => {'two' => {}},
          'four' => {}
        }
        identifying_fields = ['one.two.three', 'four.five.six']
        error = TurbotRunner::Validator.validate('primary-data', record, identifying_fields, Set.new)
        expect(error).to eq('There were no values provided for any of the identifying fields: one.two.three, four.five.six')
      end

      specify 'with record missing some identifying fields' do
        record = {
          'sample_date' => '2014-06-01',
          'source_url' => 'http://example.com/123',
          'one' => {'two' => {'three' => 123}}
        }
        identifying_fields = ['one.two.three', 'four.five.six']
        error = TurbotRunner::Validator.validate('primary-data', record, identifying_fields, Set.new)
        expect(error).to eq(nil)
      end

      specify 'with record missing no identifying fields' do
        record = {
          'sample_date' => '2014-06-01',
          'source_url' => 'http://example.com/123',
          'one' => {'two' => {'three' => 123}},
          'four' => {'five' => {'six' => 456}}
        }
        identifying_fields = ['one.two.three', 'four.five.six']
        error = TurbotRunner::Validator.validate('primary-data', record, identifying_fields, Set.new)
        expect(error).to eq(nil)
      end
    end

    specify 'with duplicate record' do
      record = {
        'sample_date' => '2014-06-01',
        'source_url' => 'http://example.com/123',
        'number' => 123
      }

      seen_uids = Set.new
      error = TurbotRunner::Validator.validate('primary-data', record, ['number'], seen_uids)
      expect(error).to eq(nil)

      error = TurbotRunner::Validator.validate('primary-data', record, ['number'], seen_uids)
      expect(error).to eq('Already seen record with these identifying fields: {"number"=>123}')
    end

    context 'with schema location passed in' do
      before do
        @schema_location = File.join(File.dirname(__FILE__), '..', 'support', 'local_schema.json')
        @valid_record = {
          'uid' => '123'
        }
        @invalid_record = {
          'uid' => 123
        }
      end

      specify 'should use schema at location for validation' do
        expect(TurbotRunner::Validator.validate(nil, @valid_record, ['uid'], nil, @schema_location)).to be_nil
        expect(TurbotRunner::Validator.validate(nil, @invalid_record, ['uid'], nil, @schema_location)).not_to be_nil
      end
    end
  end

  describe '.identifying_hash' do
    specify 'returns expected hash' do
      record = {'aaa' => 'bbb', 'yyy' => 'zzz'}
      expect(TurbotRunner::Validator.identifying_hash(record, ['aaa'])).to eq({'aaa' => 'bbb'})

      record = {'aaa' => {'bbb' => 'ccc'}, 'yyy' => 'zzz'}
      expect(TurbotRunner::Validator.identifying_hash(record, ['aaa.bbb'])).to eq({'aaa.bbb' => 'ccc'})
    end

    specify 'returns empty hash for records with no values for identifying fields' do
      record = {'yyy' => 'zzz'}
      expect(TurbotRunner::Validator.identifying_hash(record, ['aaa'])).to eq({})
    end

    specify 'returns nil for records where value of identifying field is a hash' do
      record = {'aaa' => {'bbb' => 'ccc'}, 'yyy' => 'zzz'}
      expect(TurbotRunner::Validator.identifying_hash(record, ['aaa'])).to be(nil)

      record = {'aaa' => {'bbb' => {'ccc' => 'ddd'}}, 'yyy' => 'zzz'}
      expect(TurbotRunner::Validator.identifying_hash(record, ['aaa.bbb'])).to be(nil)
    end
  end
end
