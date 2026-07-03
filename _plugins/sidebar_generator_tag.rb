# Jekyll plugin: Generates an html sidebar from the built site map.


require_relative './debug_utils'
require_relative './title_format_utils'


class SidebarGeneratorTag < Liquid::Tag
    # Syntax is simple: it requires no arguments, it just reads the global site data.
    Syntax = /^\s*$/o 
    include DebugUtils
    # DebugUtils.set_debug_mode(true)
    # Thread.current[:debug_mode] = true
    # self.set_debug_mode(true)
    include TitleFormatMixin

    # Overriding the class-level attribute inherited from the DebugUtils mixin
    def self.debug_mode
        # true
        false
    end
    # To override just a specific place in a method,
    # wrap that place in between the two lines:
    # ````
    # DebugUtils.set_debug_mode(true)
    # DebugUtils.set_debug_mode(false)
    # ````
    # For example:
    # ```
    # def a_method()
    #     DebugUtils.set_debug_mode(true)
    #     self.debug_print("SidebarGeneratorTag", "a_method", "This will print!")
    #     DebugUtils.set_debug_mode(false)
    # ```

    def initialize(_tag_name, markup, _parse_context)
        super
        # Since we aren't expecting arguments, the regex check simply confirms the tag structure.
    end

    def render(context)
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
        self.debug_json("SidebarGeneratorTag", "render", "Site map data: ",site_map)
        name = "site_content"
        node = site_map[name]
        sidebar_html = build_sidebar_html(node, name, 0, context, "/", "")
        # DebugUtils.set_debug_mode(false)
        
        return sidebar_html
    end

    # Register the tag
    Liquid::Template.register_tag('sidebar_nav', SidebarGeneratorTag)

private    
    # The core recursive function
    # @param node: The hash container currently being processed (e.g., the 'steps' node).
    # @param name: The name (key) of the current node.
    # @param level: The current depth level.
    # @param context: The Liquid context object (needed for data lookup).
    # @param base_path: The path to append to the URL (e.g., "/site_content_map_root").
    # @param current_path: The accumulated path (e.g., "/site_content/steps").
    def build_sidebar_html(node, name, level, context, base_path, current_path)
        self.debug_print("SidebarGeneratorTag", "build_sidebar_html", "Starting with node name '#{name}' on level '#{level}'")
        baseurl = context.registers[:site].config["baseurl"].to_s
        # Start the overall list item container
        html = ""
        if level > 0
            html += "<li class=\"sidebar-item level-#{level}\">\n"
        end

        # 1. Check for the leaf page (The actual link)
        page_data = node["__page__"]
        self.debug_print("SidebarGeneratorTag", "build_sidebar_html", "Node name '#{name}' page data: '#{page_data}'")
        if page_data
            # This node is a page, so it must render a link.
            title = page_data["title"]
            url = page_data["url"]
            
            # We wrap the link in a top-level list item to maintain the structure
            # html += "<li class=\"sidebar-item level-#{level}\">#{build_link_tag(url, title)}</li>\n"
            page_html = self.build_link_tag(baseurl, url, title)
        else
            css_class="sidebar-item level-#{level}"
            page_html = self.build_nolink_tag(name, css_class: css_class)
        end
        
        # 2. Check for immediate children (The loop that iterates over subkeys)
        children = node["__children__"]
        self.debug_print("SidebarGeneratorTag", "build_sidebar_html", "Node name '#{name}' children data: '#{children}'")
        if children.is_a?(Hash) && !children.empty?
            if level > 0
                sidebar_icon = File.read(File.join(Dir.pwd, "_includes", "collapsible_sidebar_icon.html"))
                # Make the span for the vertical bar
                html += "<span class=\"sidebar-item level-#{level} bar-container\">\n"
                html += "\t<div class=\"sidebar-item level-#{level} bar\"></div>\n"
                html += "\t<div class=\"sidebar-item level-#{level} bar-content-wrapper\">"
                html += "\t\t<button class=\"sidebar-item-toggle sidebar_item_toggle_level-#{level}\" id=\"\##{name}_submenu\" data-target=\"#{name}_submenu\" aria-expanded=\"false\" onclick=\"toggleAccordion(this)\">\n"
                html += "\t\t\t<span class=\"sidebar-icon\">\n"
                html += sidebar_icon
                html += "\t\t\t</span>\n"
                html += page_html
                html += "\t\t</button>\n"
                
            end
            # The key structure is: <ul><li>Key: {__children__: {...}, __page__:{...}}</li></ul>
            
            # Start the list container
            html += "<ul class=\"submenu level-#{level}\" id=\"#{name}_submenu\""
            if level > 0
                html += "style=\"display: none;\""
            end
            html += ">\n"
            
            # Iterate over all immediate children of the current node
            children.each do |subkey, child_node|
                # The subkey is the text segment ("steps", "test")
                
                # Append the recursive HTML structure for that child
                html += build_sidebar_html(child_node, subkey, level + 1, context, base_path, nil)
            end
            
            html += "</ul>\n"
            if level > 0
                html += "\t</div>\n"
                html += "</span>\n"
            end
        else
            html += page_html
        end
        if level > 0
            html += "</li>\n"
        end
        
        return html
    end
    # DebugUtils.set_debug_mode(false)
end
