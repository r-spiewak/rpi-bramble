# From https://hblok.net/blog/posts/2016/10/23/jekyll-include-partial-snippets-of-code/

class IncludeLines < Liquid::Tag
    Syntax = /(#{Liquid::QuotedFragment}+)\s(\d+)\s(\d+)\s\z/o
    
    def initialize(tag_name, markup, options)
      super
      if markup =~ Syntax
        @file = $1
        @startline = $2.to_i
        @endline = $3.to_i
      else
        raise "Syntax error in includelines: " + markup
      end
    end

    def render(context)
      lines = IO.readlines(context.evaluate(@file))
      part = lines.drop(@startline)
      part.take(@endline - @startline)
    end

  end

  Liquid::Template.register_tag('include_lines', IncludeLines)