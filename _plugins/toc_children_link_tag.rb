# Jekyll plugin: Generates a list of immediate children
# from the built site map.

require_relative './debug_utils'
require_relative './title_format_utils'
require_relative './toc_children_link_renderer'


class ImmediateChildrenTOCGeneratorTag < Liquid::Tag
    Syntax = /^\s*$/o 
    include DebugUtils
    include TitleFormatMixin
    include ImmediateChildrenTOCRenderer

    # Overriding the class-level attribute inherited from the DebugUtils mixin
    def self.debug_mode
        # true
        false
    end

    def initialize(_tag_name, markup, _parse_context)
        super
        # Since we aren't expecting arguments, the regex check simply confirms the tag structure.
    end

    def render(context)
        self.debug_print("ImmediateChildrenTOCGeneratorTag", "render", "Started rendering Immediate Children ToC!")
        # 1. Safely retrieve the map from the global site data.
        # We must use context.data here, as context represents the Site object.
        site_map = context["site"]["data"]["site_content_map"]
        
        if site_map.nil? || site_map.empty?
            return "<p style=\"color:red;\">Sitemap map not found or empty. Ensure the SiteContentMapBuilder has run successfully.</p>"
        end

        # 2. Start the recursive process.
        # We pass the root node, the full context (for URL lookups), and an empty path.
        # The result of this function is the complete HTML string.
        # DebugUtils.set_debug_mode(true)
        self.debug_json("ImmediateChildrenTOCGeneratorTag", "render", "Site map data: ", site_map)
        name = "site_content"
        node = site_map[name]
        # page_url = context['page']["url"]
        page = context["page"]
        # DebugUtils.set_debug_mode(true)
        self.debug_json("ImmediateChildrenTOCGeneratorTag", "render", "Page: ", page)
        # sidebar_html = build_sidebar_html(node, name, 0, context, "/", "")
        # DebugUtils.set_debug_mode(true)
        children = get_immediate_children_container(site_map, page)
        baseurl = context.registers[:site].config["baseurl"].to_s
        page_html = self.generate_immediate_children_toc(children, baseurl)
        # DebugUtils.set_debug_mode(false)
        
        # name = "Rendered `ImmediateChildrenTOCGeneratorTag`!"
        # page_html = self.build_nolink_tag(name, style: "color:blue;")
        return page_html
    end

    # Register the tag
    Liquid::Template.register_tag('toc_immediate_children', ImmediateChildrenTOCGeneratorTag)

private
    def get_immediate_children_container(site_map, current_page)
        page_url = current_page["url"]
        parts = page_url.split("/").reject(&:empty?)
        if parts.empty?
            self.debug_warning("ImmediateChildrenTOCGeneratorTag", "get_immediate_children_container", "No parts for page with url '#{page_url}'; assuming root.")
            site_content = site_map["site_content"]
            if site_content.empty?
                children = nil
            else
                children = site_content["__children__"]
            end
        else
            current = site_map
            parts.each_with_index do |part, index|
                self.debug_print("ImmediateChildrenTOCGeneratorTag", "get_immediate_children_container", "Current part (index: #{index}): #{part}")
                if current[part] == nil or current[part].empty?
                    self.debug_warning("ImmediateChildrenTOCGeneratorTag", "get_immediate_children_container", "Empty part... breaking.")
                    break
                else
                    current = current[part]["__children__"]
                end
            end
            children = current
        end
        # node = site_map[current_page["id"]]
        self.debug_json("ImmediateChildrenTOCGeneratorTag", "get_immediate_children_container", "Children: ", children)
        return children
    end
end
