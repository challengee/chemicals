require 'thread'

module Chemicals
  class Template

    NS = 'http://piesync.com/xml/chemicals'

    def initialize(template, options = {})
      @template = Nokogiri::XML(template) { |c| c.noblanks }
      @options = {
        symbolize_keys: true
      }.merge!(options)
      @cache = {}
      @semaphore = Mutex.new
    end

    # returns the raw template
    def raw
      @template
    end

    # get the configuration for an xpath expression
    def for path, namespaces = nil
      @semaphore.synchronize do
        if @cache.has_key?(path)
          @cache[path]
        else
          @cache[path] = if namespaces
            for_node @template.at(canonicalize(path), namespaces)
          else
            for_node @template.at(canonicalize(path))
          end
        end
      end
    end

    # get the configuration for a config node
    def for_node config_node
      # nil if no config node
      return nil unless config_node
      return nil if @template.at(canonicalize(config_node.path)).nil?
      # configuation is different in every case
      config = case config_node
        when Nokogiri::XML::Text
          config_node.content == '@' ? {} : {
            as: @options[:symbolize_keys] ? config_node.content.to_sym : config_node.content
          }
        when Nokogiri::XML::Attr
          {
            as: @options[:symbolize_keys] ? config_node.value.to_sym : config_node.value
          }
        when Nokogiri::XML::Element
          as = attribute(config_node, :as)
          {
            as: as ? (@options[:symbolize_keys] ? as.to_sym : as) : nil,
            mode: mode(config_node, as)
          }
      end
    end

    def mode config_node, as
      mode = attribute(config_node, :mode)
      if mode
        mode.to_sym
      elsif as # only merge if we parse this node.
        :merge
      else
        nil
      end
    end

    # add the required namespaces to a node
    def add_namespaces node
      raw.root.namespace_definitions.each do |ns|
        node.add_namespace_definition ns.prefix, ns.href if ns.href != NS
      end
    end

    # parse a document
    def parse source
      Parser.new(self).parse source
    end

    # render a hash
    def render source
      Renderer.new(self).render source
    end

    private

    def attribute node, name
      node.attribute_with_ns(name.to_s, NS).value if node.namespaced_key?(name.to_s, NS)
    end

    # canonicalize an xpath expression
    def canonicalize xpath
      # this means removing indexes
      xpath.gsub(/\[[^\]]*\]/, '')
    end
  end
end
