module Chemicals
  class Parser
    def initialize template
      @template = template
    end

    def parse source
      @namespaces = {}
      @subparse = Proc.new do |node|
        parse_node(node, @template.for(node.path, @namespaces)) || {}
      end
      # get the document in nokogiri without blanks
      # or if the source is already a nokogiri node, then assume it is without blanks.
      root = if source.kind_of? Nokogiri::XML::Node
        source.document.root
      else
        Nokogiri::XML(source.to_s) { |c| c.noblanks }.root
      end
      raise ArgumentError, 'source has no root' unless root
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
      parsed = source.children.map { |node| @subparse.(node) } +
        source.attribute_nodes.map { |node| @subparse.(node) }
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
      namespace = node.namespace
      if namespace
        href = namespace.href
        # a namespace without a prefix is a default namespace
        if !namespace.prefix
          # not mapped this namespace?
          unless @namespaces.has_key?(href)
            # define the new namespace
            ns = node.document.root.add_namespace "ns#{@namespaces.size}",
              href
            # add a mapping
            @namespaces[href] = ns
          end
          # change the namespace
          node.namespace = @namespaces[href]
        # namespace with prefix
        else
          @namespaces[href] ||= namespace
        end
      end
      node.children.each { |child| handle_namespace child }
      node.attribute_nodes.each { |child| handle_namespace child }
    end
  end
end
