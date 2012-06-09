# encoding: utf-8

require 'minitest/autorun'
require 'minitest/spec'

require 'mocha'

require_relative 'chemicals_spec_helper'

require 'chemicals'

describe Chemicals::Parser do

  it 'should be able to reuse the document if the source is already a parsed nokogiri document' do
    template, raw = ChemicalsSpecHelper.test_example :simple_text
    parsed = Nokogiri::XML(raw)
    parsed.expects(:to_s).never
    template.parse(parsed).must_equal 'John Doe'
  end

  describe 'parsing a text node' do
    it 'parses the content as the direct data of the parent node when it is aliased as @' do
      template, raw = ChemicalsSpecHelper.test_example :simple_text
      template.parse(raw).must_equal 'John Doe'
    end

    it 'parses the content wrapped into its alias' do
      template, raw = ChemicalsSpecHelper.test_example :simple_text_alias
      template.parse(raw).must_equal \
        name: 'John Doe'
    end

    it 'skips the node when no alias is provided' do
      template, raw = ChemicalsSpecHelper.test_example :skip_text_node
      template.parse(raw).must_equal \
        name: { last_name: 'Doe' }
    end
  end

  describe 'parsing an element' do
    it 'parses the content wrapped into its alias' do
      template, raw = ChemicalsSpecHelper.test_example :simple_element_alias
      template.parse(raw).must_equal \
        individual: 'John Doe'
    end

    it 'skips the element when no alias is provided' do
      template, raw = ChemicalsSpecHelper.test_example :skip_element
      template.parse(raw).must_equal \
        individual: 'John Doe'
    end
  end

  describe 'parsing a collection of elements' do
    it 'should parse empty collections' do
      template, raw = ChemicalsSpecHelper.test_example :empty_collection
      template.parse(raw).must_equal []
    end

    it 'should parse each element' do
      template, raw = ChemicalsSpecHelper.test_example :simple_collection
      template.parse(raw).must_equal \
        emails: [
          'john.doe@gmail.com',
          'john@acme.com'
        ]
    end

    it 'should parse multiple collections independently' do
      template, raw = ChemicalsSpecHelper.test_example :multiple_collections
      template.parse(raw).must_equal \
        contact: {
          emails: [
            'john.doe@gmail.com',
            'john@acme.com'
          ],
          phone_numbers: ['1', '2']
        }
    end

    it 'should be able to collect in the presence of other elements' do
      template, raw = ChemicalsSpecHelper.test_example :mixed_collection
      template.parse(raw).must_equal \
        contact: {
          emails: [
            'john.doe@gmail.com',
            'john@acme.com'
          ],
          name: 'John Doe'
        }
    end

    it 'should be able to collect multiple collections in the presence of other elements' do
      template, raw = ChemicalsSpecHelper.test_example :mixed_collections
      template.parse(raw).must_equal \
        contact: {
          emails: [
            { address: 'john.doe@gmail.com', label: 'work' },
            { address:'john@acme.com' }
          ],
          phones: ['1'],
          name: 'John Doe'
        }
    end

    it 'should be able to extreme collect multiple collections in the presence of other elements' do
      template, raw = ChemicalsSpecHelper.test_example :mixed_collections_extreme
      template.parse(raw).must_equal \
        [{
          emails: [
            { address: 'john.doe@gmail.com', label: 'work' },
            { address:'john@acme.com' }
          ],
          phones: ['1'],
          name: 'John Doe'
        },
        {
          phones: ['1', '2', '3'],
          addresses: [{ country: 'Belgium', country_code: 'BE',
            street: 'Désiré Van Monckhovenstraat', housenumber: '123' }]
        }]
    end
  end

  it 'should parse mixed elements, collections and text nodes' do
      template, raw = ChemicalsSpecHelper.test_example :mixed_elements_text
      template.parse(raw).must_equal \
        [
          {
            name: { given: 'John', family: 'Doe' },
            emails: ['john.doe@gmail.com', 'john@acme.com'],
            phones: [
              { country: 'Belgium', number: '1' },
              { country: 'USA', number: '2' }
            ]
          },
          {
            name: { given: 'Jane' },
            emails: [ 'jane.doe@gmail.com' ]
          }
        ]
  end

  describe 'parsing attributes' do
    it 'should parse attributes with aliases' do
      template, raw = ChemicalsSpecHelper.test_example :simple_attributes
      template.parse(raw).must_equal \
        full_name: 'John Doe'
    end

    # it 'should not parse attributes not mentioned in the template' do
    #   template, raw = ChemicalsSpecHelper.test_example :ignore_attribute
    #   template.parse(raw).must_equal({})
    # end

    it 'should mix attributes and aliased text nodes' do
      template, raw = ChemicalsSpecHelper.test_example :text_attributes
      template.parse(raw).must_equal \
        age: '24',
        name: 'John Doe'
    end

    it 'should preserve empty attributes' do
      template, raw = ChemicalsSpecHelper.test_example :preserve_empty_attributes
      template.parse(raw).must_equal \
        first_name: '',
        last_name: 'Doe'
    end
  end

  it 'should parse mixed elements, collections, text nodes, attributes and ignore useless nodes' do
      template, raw = ChemicalsSpecHelper.test_example :mixed_elements_text_attributes
      template.parse(raw).must_equal \
        [
          {
            name: { given: 'John', family: 'Doe' },
            emails: [
              { label: 'home', address: 'john.doe@gmail.com' },
              { address: 'john@acme.com' }
            ],
            phones: [
              { country: 'Belgium', number: '1', system: 'sap' },
              { country: 'USA', number: '2' }
            ]
          },
          {
            name: { given: 'Jane' },
            emails: [{ label: 'work', address: 'jane.doe@gmail.com' }]
          }
        ]
  end

  it 'should be able to parse chinese characters' do
    template, raw = ChemicalsSpecHelper.test_example :chinese
    template.parse(raw).must_equal '你好世界'
  end

  it 'should be able to parse namespaces' do
    template, raw = ChemicalsSpecHelper.test_example :namespaces
    template.parse(raw).must_equal \
      name: { age: '24', first_name: 'John', last_name: 'Doe' }
  end

  it 'should be able to deal with a root default namespace' do
    template, raw = ChemicalsSpecHelper.test_example :default_namespaces
    template.parse(raw).must_equal \
      name: { age: '24', first_name: 'John', last_name: 'Doe', company: 'PieSync', title: 'CEO' }
  end

  it 'should be able to deal with multiple default namespaces' do
    template, raw = ChemicalsSpecHelper.test_example :multiple_default_namespaces
    template.parse(raw).must_equal \
      name: { age: '24', first_name: 'John', last_name: 'Doe', company: 'PieSync', title: 'CEO' }
  end

  it 'should detect if namespace prefixes are named differently in the template' do
    template, raw = ChemicalsSpecHelper.test_example :different_prefix_names
    template.parse(raw).must_equal \
      name: { age: '24', first_name: 'John', last_name: 'Doe' }
  end

  it 'should be able to parse sudden namespaces' do
    template, raw = ChemicalsSpecHelper.test_example :sudden_namespaces
    template.parse(raw).must_equal \
      name: { age: '24', first_name: 'John', last_name: 'Doe', gender: 'male' }
  end

  it 'should parse parts without extracted data as an empty hash' do
    template, raw = ChemicalsSpecHelper.test_example :no_data
    template.parse(raw).must_equal name: {}
  end

  # it 'should be able to parse with partial templates' do
  #   template, raw = ChemicalsSpecHelper.test_example :partial_template
  #   template.parse(raw).must_equal \
  #     balance: { currency: 'dollar', amount: '1.000.000.000' }
  # end

  it 'should be reasonably fast' do
    template, raw = ChemicalsSpecHelper.test_example :mixed_elements_text
    1000.times do
      template.parse(raw)
    end
  end
end