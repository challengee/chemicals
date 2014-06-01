require 'minitest'
require 'minitest/autorun'
require 'minitest/spec'

require 'mocha'

require 'yaml'

require 'chemicals'

module ChemicalsSpecHelper

  EXAMPLES = YAML.load(IO.read File.expand_path('../chemicals/examples.yml', __FILE__))

  def self.test_example name
    returns = [Chemicals::Template.new(EXAMPLES[name.to_s]['template']), EXAMPLES[name.to_s]['raw']]
    returns << EXAMPLES[name.to_s]['raw_render'] if EXAMPLES[name.to_s]['raw_render']
    return *returns
  end

  def self.format xml
    Nokogiri::XML(xml) { |c| c.noblanks }.root.to_xml
  end
end
