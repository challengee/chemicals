module Chemicals
  class Parser
    def initialize template
      @template = template
    end

    def parse source
      @namespaces = {}
      # get the document in nokogiri without blanks
      # or if the source is already a nokogiri node, then assume it is without blanks.
      root = if source.kind_of? Nokogiri::XML::Node
        source.document.root
      else
        Nokogiri::XML(source.to_s) { |c| c.noblanks }.root
      end
      # delete all default namespaces and map the new ones in @namespaces
      handle_namespace root
      # map to a general namespace prefix => href hash
      @namespaces = Hash[(@namespaces.values + root.namespace_definitions).map { |ns|
        [ns.prefix, ns.href] if ns.prefix
      }.compact]
      # begin parsing with the root node
      parse_node root, @template.for(root.path, @namespaces)
    end

    private

    def parse_node source, config
      return nil unless config
      # parse all child nodes and attribute nodes
      parsed = (source.children.to_a + source.attribute_nodes).map do |node|
        # parse node with the correspondent config (using node xpath)
        parse_node(node, @template.for(node.path, @namespaces)) || {}
      end
      # reject nil values
      parsed.reject! { |key, value| !value } if parsed.kind_of? Hash
      # in arrays reject empty hashes
      parsed.reject! { |value| value.empty? } if parsed.kind_of? Array
      # we have a few cases here
      parsed = case source
        when Nokogiri::XML::Text
          source.content
        when Nokogiri::XML::Attr
          source.content
        when Nokogiri::XML::Element
          # an array of arrays is flattened
          if parsed.kind_of?(Array) && parsed.all? { |part| part.kind_of? Array }
            parsed.flatten
          # everything else is merged
          else
            parsed.inject { |result, part|
              # internal arrays are added
              result.merge!(part) { |key, old_value, new_value|
                # This way mixed collections come together.
                old_value + new_value
              }
            }
          end
        end
      # If nothing got parsed but we expect a hash then make it a hash!
      if parsed.empty? && config[:mode] == :merge
        parsed = {}
      end
      # wrap in array if collecting
      parsed = [parsed] if config[:mode] == :collect
      # wrap in alias
      parsed = {config[:as] => parsed} if config.has_key?(:as) && !config[:as].nil?
      # return parsed version and reject all nil values!
      parsed
    end

    def handle_namespace node
      if node.namespace
        # a namespace without a prefix is a default namespace
        if !node.namespace.prefix
          # not mapped this namespace?
          unless @namespaces.has_key? node.namespace.href
            # define the new namespace
            node.document.root.add_namespace_definition "ns#{@namespaces.size}",
              node.namespace.href
            # add a mapping
            @namespaces[node.namespace.href] = node.document.root.namespace_definitions.find { |ns|
              ns.prefix && ns.href == node.namespace.href
            }
          end
          # change the namespace
          node.namespace = @namespaces[node.namespace.href]
        # namespace with prefix
        else
          @namespaces[node.namespace.href] ||= node.namespace
        end
      end
      # do the same for all child elements and attributes
      (node.children.to_a + node.attribute_nodes).each { |child| handle_namespace child }
    end
  end
end
