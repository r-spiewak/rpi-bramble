class RootIncludeLines < Liquid::Tag
    Syntax = /(#{Liquid::QuotedFragment}+)\s(\d+)\s(\d+)\s\z/o
    
    def initialize(_tag_name, markup, _parse_context)
      super
      if markup =~ Syntax
        @file = $1.strip
        @startline = $2.to_i
        @endline = $3.to_i
      else
        raise "Syntax error in includelines: " + markup
      end
      #@markup = markup.strip
    end
  
    def render(context)
      expanded_path = Liquid::Template.parse(@file).render(context)
      root_path = File.expand_path(context.registers[:site].config['source'])
      final_path = File.join(root_path, expanded_path)
      lines = read_file(final_path, context)
      #lines = IO.readlines(context.evaluate(@file))
      part = lines.drop(@startline)
      part.take(@endline - @startline)
    end
  
    def read_file(path, context)
      file_read_opts = context.registers[:site].file_read_opts
      File.readlines(path, **file_read_opts)
    end
  end
  
  Liquid::Template.register_tag('root_include_lines', RootIncludeLines)