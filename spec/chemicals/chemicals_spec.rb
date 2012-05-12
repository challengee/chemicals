# encoding: utf-8

require 'minitest/spec'
require 'minitest/autorun'

require 'chemicals'





describe Chemicals::Renderer do
  describe 'rendering a text node' do
    it 'should render the element value directly in the text node when the text node is aliased as @' do
      template, raw = ChemicalsSpecHelper.test_example :simple_text
      template.render('John Doe').to_xml.must_equal ChemicalsSpecHelper.format(raw)
    end

    it 'should render the content unwrapped from its alias' do
      template, raw = ChemicalsSpecHelper.test_example :simple_text_alias
      template.render(name: 'John Doe').to_xml.must_equal ChemicalsSpecHelper.format(raw)
    end
  end

  describe 'rendering an attribute' do
    it 'should render attributes with aliases' do
      template, raw = ChemicalsSpecHelper.test_example :simple_attributes
      template.render(full_name: 'John Doe').to_xml.must_equal ChemicalsSpecHelper.format(raw)
    end
  end

  describe 'rendering an element' do
    it 'should unwrap contents in aliased elements' do
      template, raw = ChemicalsSpecHelper.test_example :simple_element_alias
      template.render(individual: 'John Doe').to_xml.must_equal ChemicalsSpecHelper.format(raw)
    end

    it 'should skip an element when no alias is provided' do
      template, raw = ChemicalsSpecHelper.test_example :skip_element
      template.render(individual: 'John Doe').to_xml.must_equal ChemicalsSpecHelper.format(raw)
    end
  end

  describe 'rendering a collection of elements' do
    it 'should render each element' do
      template, raw = ChemicalsSpecHelper.test_example :simple_collection
      template.render(emails: [
        'john.doe@gmail.com',
        'john@acme.com'
      ]).to_xml.must_equal ChemicalsSpecHelper.format(raw)
    end

    it 'should render multiple collections independently' do
      template, raw = ChemicalsSpecHelper.test_example :multiple_collections
      template.render(
        contact: {
          emails: [
            'john.doe@gmail.com',
            'john@acme.com'
          ],
          phone_numbers: ['1', '2']
        }).to_xml.must_equal ChemicalsSpecHelper.format(raw)
    end

    it 'should be able to render collections in the presence of other elements' do
      template, raw = ChemicalsSpecHelper.test_example :mixed_collection
      template.render( \
        contact: {
          emails: [
            'john.doe@gmail.com',
            'john@acme.com'
          ],
          name: 'John Doe'
        }).to_xml.must_equal ChemicalsSpecHelper.format(raw)
    end

    it 'should be able to render multiple collections in the presence of other elements' do
      template, raw = ChemicalsSpecHelper.test_example :mixed_collections
      template.render(
        contact: {
          emails: [
            { address: 'john.doe@gmail.com', label: 'work' },
            { address: 'john@acme.com' }
          ],
          phones: ['1'],
          name: 'John Doe'
        }).to_xml.must_equal ChemicalsSpecHelper.format(raw)
    end

    it 'should be able to extreme parse multiple collections in the presence of other elements' do
      template, raw = ChemicalsSpecHelper.test_example :mixed_collections_extreme
      template.render(
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
        }]).to_xml.must_equal ChemicalsSpecHelper.format(raw)
    end
  end

  it 'should render mixed elements, collections and text nodes' do
    template, raw, raw_render = ChemicalsSpecHelper.test_example :mixed_elements_text
    template.render(
        [{
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
      ]).to_xml.must_equal ChemicalsSpecHelper.format(raw_render)
  end

  it 'should render mixed elements, collections, text nodes, attributes and ignore useless nodes' do
      template, raw, raw_render = ChemicalsSpecHelper.test_example :mixed_elements_text_attributes
      template.render([
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
      ]).to_xml.must_equal ChemicalsSpecHelper.format(raw_render)
  end

  describe 'rendering attributes' do
    it 'should render attributes with aliases' do
      template, raw = ChemicalsSpecHelper.test_example :simple_attributes
      template.render(full_name: 'John Doe').to_xml.must_equal ChemicalsSpecHelper.format(raw)

    end

    it 'should not render attributes not mentioned in the template' do
      template, raw = ChemicalsSpecHelper.test_example :ignore_attribute
      template.render({}).must_equal nil
    end

    it 'should mix attributes and aliased text nodes' do
      template, raw = ChemicalsSpecHelper.test_example :text_attributes
      template.render(age: '24', name: 'John Doe').to_xml.must_equal ChemicalsSpecHelper.format(raw)

    end
  end

  it 'should be able to render chinese characters' do
    template, raw = ChemicalsSpecHelper.test_example :chinese
    template.render('你好世界').to_xml.must_equal ChemicalsSpecHelper.format(raw)
  end

  it 'should be able to render namespaces' do
    template, raw = ChemicalsSpecHelper.test_example :namespaces
    template.render(
      name: { age: '24', first_name: 'John', last_name: 'Doe' }).to_xml.must_equal ChemicalsSpecHelper.format(raw)

  end

  it 'should be reasonably fast' do
    template, raw = ChemicalsSpecHelper.test_example :mixed_elements_text
    1000.times do
      template.render(
          [{
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
        ])
    end
  end
end

__END__

