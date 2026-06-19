

module TitleFormatMixin
    # Helper method for formatting links
    def build_link_tag(baseurl, url, title)
        # Use the context to access the current domain/base URL if needed, 
        # otherwise, just use the URL path.
        "<a href=\"#{baseurl}#{url}\">#{title}</a>\n"
    end

    # Helper method for formatting non-links
    def build_nolink_tag(name, css_class: "main", style: "color:orange;")
        "<p style=#{style} class=#{css_class}>#{name}</p>\n"
    end
end
