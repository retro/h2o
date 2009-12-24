module H2o
  module Tags
    # Recurse tag allows rendering of tree structures. The template should look something like this:
    # {% recurse all_categories with children as category %}
    #   <ul>
    #     {% loop %}
    #       <li>
    #         <h{{ level }}>{{ category.title }}</h{{ level }}>
    #         {% children %}
    #       </li>
    #     {% endloop %}
    #   </ul>
    # {% endrecurse %}
    class Recurse < Tag
      
      Syntax = /(#{H2o::NAME_RE})\s+with\s+(#{H2o::IDENTIFIER_RE})\s+as\s+(#{H2o::IDENTIFIER_RE})/
      
      def initialize(parser, argstring)
        @body    = parser.parse(:loop, :children, :endloop, :endrecurse)
        @child   = parser.parse(:children, :endloop, :endrecurse) if parser.token && parser.token.include?('loop')
        @enditem = parser.parse(:endloop, :endrecurse) if parser.token && parser.token.include?('children')
        @end     = parser.parse(:endrecurse) if parser.token && parser.token.include?('endloop')        
        if argstring =~ Syntax
          @collection_id   = $1.to_sym
          @children_method = $2.to_sym
          @item_id         = $3.to_sym
        else
          raise SyntaxError, "Invalid recurse syntax "
        end
      end
      
      def render(context, stream)
        collection = context.resolve(@collection_id)
        @body.render(context, stream)
        context.stack do
          level = context[:level] || 1
          collection.each do |item|
            context[@item_id] = item
            context[:level] = level
            @child.render(context, stream)
            children = item.respond_to?(@children_method) ? item.send(@children_method) : item[@children_method]
            unless children.empty?
              stream << self.render(Context.new({@collection_id => children, :level => (level + 1)}), [])
            end
            @enditem.render(context, stream)
          end
        end
        @end.render(context, stream)
      end
      
      Tags.register(self, :recurse)
      
    end
  end
end