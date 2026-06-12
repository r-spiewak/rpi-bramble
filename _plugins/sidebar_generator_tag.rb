# Jekyll plugin: Generates an html sidebar from the built site map.

# # Colored Text
# COLORS = {
#     "WHITE" => "\e[0m",
#     "RED" => "\e[31m",
#     "GREEN" => "\e[32m",
#     "BLUE" => "\e[34m",
#     "YELLOW" => "\e[33m"
# }

# # Text Color States
# COLORS["DEBUG"] = COLORS["BLUE"]
# COLORS["NORMAL"] = COLORS["WHITE"]
# COLORS["ERROR"] = COLORS["RED"]
# COLORS["WARNING"] = COLORS["YELLOW"]

# DEBUG = true
# if DEBUG
#     require 'json'
# end

# def debug_print(class_name, method, message, *args)
#     if DEBUG
#         # Use a specific tag for easier searching later
#         puts "#{COLORS['DEBUG']}--- [DEBUG][#{class_name}][#{method}] ---#{COLORS['NORMAL']} #{message} #{args.join(' ')}"
#     end
# end

# def debug_p(obj)
#     if DEBUG
#         # Use a specific tag for easier searching later
#         p obj
#     end
# end

# def debug_json(class_name, method, message, obj)
#     if DEBUG
#         json_str = JSON.pretty_generate(obj, indent: "    ")
#         puts "#{COLORS['DEBUG']}--- [DEBUG][#{class_name}][#{method}] ---#{COLORS['NORMAL']} #{message} #{json_str}"
#     end
# end

require_relative './debug_utils'


class SidebarGeneratorTag < Liquid::Tag
    # Syntax is simple: it requires no arguments, it just reads the global site data.
    Syntax = /^\s*$/o 
    include DebugUtils
    # DebugUtils.set_debug_mode(true)
    # Thread.current[:debug_mode] = true
    # self.set_debug_mode(true)

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
    # Helper method for formatting links
    def build_link_tag(url, title)
        # Use the context to access the current domain/base URL if needed, 
        # otherwise, just use the URL path.
        "<a href=\"#{url}\">#{title}</a>\n"
    end

    # Helper method for formatting links
    def build_nolink_tag(name, level)
        "<p style=\"color:orange;\" class=\"sidebar-item level-#{level}\">#{name}</p>\n"
    end
    
    # The core recursive function
    # @param node: The hash container currently being processed (e.g., the 'steps' node).
    # @param name: The name (key) of the current node.
    # @param level: The current depth level.
    # @param context: The Liquid context object (needed for data lookup).
    # @param base_path: The path to append to the URL (e.g., "/site_content_map_root").
    # @param current_path: The accumulated path (e.g., "/site_content/steps").
    def build_sidebar_html(node, name, level, context, base_path, current_path)
        self.debug_print("SidebarGeneratorTag", "build_sidebar_html", "Starting with node name '#{name}' on level '#{level}'")
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
            page_html = build_link_tag(url, title)
        else
            page_html = build_nolink_tag(name, level)
        end
        
        # 2. Check for immediate children (The loop that iterates over subkeys)
        children = node["__children__"]
        self.debug_print("SidebarGeneratorTag", "build_sidebar_html", "Node name '#{name}' children data: '#{children}'")
        if children.is_a?(Hash) && !children.empty?
            if level > 0
                # Make the span for the vertical bar
                html += "<span class=\"sidebar-item level-#{level} bar\">\n"
                sidebar_icon = File.read(File.join(Dir.pwd, "_includes", "collapsible_sidebar_icon.html"))
                html += "<button class=\"sidebar-item-toggle sidebar_item_toggle_level-#{level}\" id=\"\##{name}_submenu\" data-target=\"#{name}_submenu\" aria-expanded=\"false\" onclick=\"toggleAccordion(this)\">\n"
                html += "    <span class=\"sidebar-icon\">\n"
                html += sidebar_icon
                html += "    </span>\n"
                html += page_html
                html += "</button>\n"
                
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

# Sample output (to match) from Liquid sequence:
# <div class="sidenav">
#     <!-- <div style="border: 2px solid blue; padding: 10px;">
#         Pages in lookup: 1566
#     </div> -->
#     <ul class="submenu level-0" id="main_submenu">
#         <li class="sidebar-item level-1">
#             <span class="sidebar-item level-1 bar">
#                 <button class="sidebar-item-toggle sidebar_item_toggle_level-1" id="#steps_submenu" data-target="steps_submenu" aria-expanded="false" onclick="toggleAccordion(this)">
#                     <span class="sidebar-icon">
#                         <!-- This block is included via collapsible_sidebar_icon,html -->
#                         <div style="width: 12px; height: 12px; padding-left: -1px; transform: translateY(-1px);">
#                             <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 12 12" focusable="false" role="presentation" padding-left="-10px">
#                                 <path fill="currentColor" d="M1.646 3.646a.5.5 0 01.638-.057l.07.057L6 7.293l3.646-3.647a.5.5 0 01.638-.057l.07.057a.5.5 0 01.057.638l-.057.07-4 4a.5.5 0 01-.638.057l-.07-.057-4-4a.5.5 0 010-.708z"></path>
#                             </svg>
#                         </div>
#                     </span>
#                     <p style="color:orange;" class="sidebar-item level-1">Steps</p>
#                 </button>
#                 <ul class="submenu level-1" id="steps_submenu" style="display:none;">
#                     <li class="sidebar-item level-2">
#                         <a href=" /site_content/steps/2026-05-25-test-file-in-subdir.html">Test Subdir File</a>
#                     </li>
#                     <li class="sidebar-item level-2">
#                         <a href=" /site_content/steps/2024-03-12-bill-of-materials.html">Bill of Materials</a>
#                     </li>
#                     <li class="sidebar-item level-2">
#                         <a href=" /site_content/steps/2024-03-12-assembly-instructions.html">Assembly Instructions</a>
#                     </li>
#                     <li class="sidebar-item level-2">
#                         <a href=" /site_content/steps/2024-03-26-OS-setup.html">OS Setup</a>
#                     </li>
#                     <li class="sidebar-item level-2">
#                         <a href=" /site_content/steps/2024-09-26-setup-ethernet-switch-routing.html">Setup Ethernet Port Switch and Routing</a>
#                     </li>
#                     <li class="sidebar-item level-2">
#                         <a href=" /site_content/steps/2024-03-28-shared-storage.html">Shared Storage Setup</a>
#                     </li>
#                     <li class="sidebar-item level-2">
#                         <a href=" /site_content/steps/2024-03-29-install-munge.html">Munge Installation</a>
#                     </li>
#                     <li class="sidebar-item level-2">
#                         <a href=" /site_content/steps/2024-04-03-install-libaio.html">Libaio Installation</a>
#                     </li>
#                     <li class="sidebar-item level-2">
#                         <a href=" /site_content/steps/2024-04-04-install-ncurses.html">Ncurses Installation</a>
#                     </li>
#                     <li class="sidebar-item level-2">
#                         <a href=" /site_content/steps/2024-04-03-install-mysql.html">MySQL Installation</a>
#                     </li>
#                     <li class="sidebar-item level-2">
#                         <a href=" /site_content/steps/2024-04-03-install-slurm.html">Slurm Installation</a>
#                     </li>
#                 </ul>
#             </span>
#         </li>
#         <li class="sidebar-item level-1">
#             <span class="sidebar-item level-1 bar">
#                 <button class="sidebar-item-toggle sidebar_item_toggle_level-1" id="#menu-item-with-subitems_submenu" data-target="menu-item-with-subitems_submenu" aria-expanded="false" onclick="toggleAccordion(this)">
#                     <span class="sidebar-icon">
#                         <!-- This block is included via collapsible_sidebar_icon,html -->
#                         <div style="width: 12px; height: 12px; padding-left: -1px; transform: translateY(-1px);">
#                             <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 12 12" focusable="false" role="presentation" padding-left="-10px">
#                                 <path fill="currentColor" d="M1.646 3.646a.5.5 0 01.638-.057l.07.057L6 7.293l3.646-3.647a.5.5 0 01.638-.057l.07.057a.5.5 0 01.057.638l-.057.07-4 4a.5.5 0 01-.638.057l-.07-.057-4-4a.5.5 0 010-.708z"></path>
#                             </svg>
#                         </div>
#                     </span>
#                     <p style="color:orange;" class="sidebar-item level-1">Menu Item with SubItems</p>
#                 </button>
#                 <ul class="submenu level-1" id="menu-item-with-subitems_submenu" style="display:none;">
#                     <li class="sidebar-item level-2">
#                         <span class="sidebar-item level-2 bar">
#                             <button class="sidebar-item-toggle sidebar_item_toggle_level-2" id="#child-1-id_submenu" data-target="child-1-id_submenu" aria-expanded="false" onclick="toggleAccordion(this)">
#                                 <span class="sidebar-icon">
#                                     <!-- This block is included via collapsible_sidebar_icon,html -->
#                                     <div style="width: 12px; height: 12px; padding-left: -1px; transform: translateY(-1px);">
#                                         <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 12 12" focusable="false" role="presentation" padding-left="-10px">
#                                             <path fill="currentColor" d="M1.646 3.646a.5.5 0 01.638-.057l.07.057L6 7.293l3.646-3.647a.5.5 0 01.638-.057l.07.057a.5.5 0 01.057.638l-.057.07-4 4a.5.5 0 01-.638.057l-.07-.057-4-4a.5.5 0 010-.708z"></path>
#                                         </svg>
#                                     </div>
#                                 </span>
#                                 <p style="color:orange;" class="sidebar-item level-2">child-1-id</p>
#                             </button>
#                             <ul class="submenu level-2" id="child-1-id_submenu" style="display:none;">
#                                 <li class="sidebar-item level-3">
#                                     <p style="color:orange;" class="sidebar-item level-3">sub-child</p>
#                                 </li>
#                             </ul>
#                         </span>
#                     </li>
#                     <li class="sidebar-item level-2">
#                         <p style="color:orange;" class="sidebar-item level-2">child-2-id</p>
#                     </li>
#                 </ul>
#             </span>
#         </li>
#     </ul>
# </div>
