
require_relative './debug_utils'
require_relative './title_format_utils'

module ImmediateChildrenTOCRenderer
    include DebugUtils
    include TitleFormatMixin

    # Overriding the class-level attribute inherited from the DebugUtils mixin
    def self.debug_mode
        # true
        false
    end

    def generate_immediate_children_toc(children, baseurl)
        html = "<ul>\n"
        # DebugUtils.set_debug_mode(true)
        if children.is_a?(Hash) && !children.empty?
            for child, node in children
                self.debug_json("ImmediateChildrenTOCRenderer", "generate_immediate_children_toc", "Current child: ", child)
                page_data = node["__page__"]
                if page_data
                    # This node is a page, so it must render a link.
                    title = page_data["title"]
                    url = page_data["url"]
                    
                    page_html = self.build_link_tag(baseurl, url, title)
                else
                    page_html = self.build_nolink_tag(child)
                end
                html += "\t<li>\n\t\t<p class=\"site-toc-entry\">\n"
                html += page_html
                html += "\t\t</p>\n\t</li>\n"
            end
        end
        html += "</ul>\n"
        return html
        # DebugUtils.set_debug_mode(false)
    end
end
