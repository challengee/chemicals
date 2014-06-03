module Chemicals
  class Renderer

    def initialize template
      @template = template
    end

    def render source
      @subrender = Proc.new do |document, source, node|
        render_node document, source, node, true if source
      end
      # begin with a new document
      document = Nokogiri::XML::Document.new
      # add a temp node as a namespace referebce
      document.root = Nokogiri::XML::Element.new 'temp', document
      @template.add_namespaces document.root
      # now render the entire document as the new root
      document.root = render_node document, source, @template.raw.root
      # again add all required namespaces to the real root
      @template.add_namespaces document.root
      # return the root
      document.root
    end

    def render_node document, source, template, collect = true
      # the template is already the template to apply this source on
      # do nothing if there's no source
      return nil unless source && config = @template.for(template.path)
      # don't render the chemicals namespace
      return nil if template.namespace && template.namespace.href == 'http://piesync.com/xml/chemicals'
      # unwrap if necessary
      source = source[config[:as].to_sym] if config.has_key?(:as) && !config[:as].nil? && collect
      # is this a collect node? Rendering a collect node is the same as rendering the
      # template for each part of the source (and render them as a non-collect node)
      # The result are the rendered nodes.
      if collect && config[:mode] == :collect
        return source.map { |part| render_node document, part, template, false } if source
      end
      # render all children
      rendered = template.children.map { |child| @subrender.(document, source, child) } +
        template.attribute_nodes.map { |child| @subrender.(document, source, child) }
      rendered.flatten!
      # reject all nil values
      rendered.reject! { |value| !value }
      # we again have a few cases how to render
      case template
      when Nokogiri::XML::Attr
        return unless source
        node = Nokogiri::XML::Attr.new document, template.name
        node.content = source
      when Nokogiri::XML::Text
        node = Nokogiri::XML::Text.new source, document if source
      when Nokogiri::XML::Element
        # don't render an element if it has no data in its children
        return unless !rendered.empty?
        node = Nokogiri::XML::Element.new template.name, document
        rendered.each do |child|
          # manually add attributes cause otherwise resulting in a segfault
          if child.kind_of? Nokogiri::XML::Attr
            node.set_attribute child.name, child.value
            node.attribute(child.name).namespace = child.namespace
          # add the non-attibutes
          else
            node.add_child child
          end
        end
      end
      # Add the correct namespaces!
      node.namespace = document.root.namespace_definitions.find { |ns|
        ns.href == template.namespace.href
      } if node && !template.namespace.nil?
      node
    end
  end
end
