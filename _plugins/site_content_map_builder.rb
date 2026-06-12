# frozen_string_literal: true

# Jekyll plugin: Builds a nested site content object from pages, posts, and collections
# Stores it in site.data["site_content"] for reuse in Liquid templates or other plugins.
#
# Sorting:
# - Uses `order` from front matter (integer) to sort siblings within the same directory.
# - Falls back to alphabetical by title if `order` is equal or missing.

require_relative './debug_utils'

module Jekyll
    class SiteContentMapBuilder < Generator
        # DebugUtils.set_debug_mode(false)
        safe true
        priority :low
        include DebugUtils

        def generate(site)
            all_docs = gather_all_docs(site)
            tree = build_tree(all_docs)
            site.data["site_content_map"] = tree
            return tree
        end

        private

        # Gather all pages, posts, and collection documents
        def gather_all_docs(site)
            docs = []
            self.debug_print("SiteContentMapBuilder", "gather_all_docs", "Starting document gathering")

            # Pages
            docs.concat(site.pages)
            self.debug_print("SiteContentMapBuilder", "gather_all_docs", "Collected #{site.pages.count} pages.")

            # Posts (Jekyll 4.x: site.posts.docs)
            if site.respond_to?(:posts) && site.posts.respond_to?(:docs)
                docs.concat(site.posts.docs)
                self.debug_print("SiteContentMapBuilder", "gather_all_docs", "Collected #{site.posts.docs.count} posts.")
            end

            # Collections (excluding posts, already added)
            site.collections.each do |label, collection|
                next if label == "posts"
                docs.concat(collection.docs) if collection && collection.docs
            end

            # # Site Content 
            # # No method `site.site_content`...
            # docs.concat(site.site_content)
            # So need to find another way to get the posts in _site_content...

            return docs
        end

        # Build a nested hash tree from an array of Jekyll::Page or Jekyll::Document objects
        def build_tree(docs)
            tree = {}
            self.debug_print("SiteContentMapBuilder", "build_tree", "Starting tree construction for #{docs.count} documents.")

            docs.each do |doc|
                self.debug_print("SiteContentMapBuilder", "build_tree", "Processing document URL: #{doc.url}")
                # 1. Skip documents without a URL or explicitly marked as non-sitemap
                next if doc.url.nil? || doc.data["sitemap"] == false

                url = doc.url
                # 2. Filter out common assets that should not generate sitemap nodes
                next if url.include?("/assets/") || url.include?("/images/") || url.match?(/\.(css|js|png|jpg)$/i)

                parts = doc.url.split("/").reject(&:empty?)

                current = tree
                parts.each_with_index do |part, index|
                    self.debug_print("SiteContentMapBuilder", "build_tree", "Processing part: #{part} (index: #{index}); parts #{parts}, current #{current}")
                    self.debug_json("SiteContentMapBuilder", "build_tree", "current", current)
                    # current[part] ||= { "__children__" => [] }
                    # current[index] ||= { "__children__" => [] }
                    current[part] ||= { "__children__" => {} }

                    if index == parts.length - 1
                        current[part]["__page__"] = {
                        # current[index]["__page__"] = {
                            "title" => doc.data["title"] || part.capitalize,
                            "url"   => doc.url,
                            "order" => doc.data["order"] || 0
                        }
                        # We don't need to set 'current' afterwards, we are done with this path.
                        break 
                    end

                    # # Traversal only happens if the segment is not the final page leaf.
                    # # This prevents trying to traverse *into* the page object itself.
                    # if index < parts.length - 1
                    #     debug_print("SiteContentMapBuilder", "build_tree", "index (#{index}) < parts.length-1 (#{parts.length - 1})")
                    #     current = current[part]["__children__"]
                    #     # current = current[index]["__children__"]
                    # else
                    #     # Reached the final node, break traversal
                    #     break 
                    # end
                    # Check existence is key here.
                    if current[part]["__children__"]
                        self.debug_print("SiteContentMapBuilder", "build_tree", "index (#{index}) < parts.length-1 (#{parts.length - 1}) for part #{part}")
                        current = current[part]["__children__"]
                        if not current.is_a?(Hash)
                            # This is a problematic branch, and is only here to safeguard
                            puts "!!! DEBUG: Path broken at segment '#{part}'; children container is not a Hash. Skipping document."
                            break
                        end
                    else
                        # This handles cases where the path segment somehow exists but has no child children array
                        current = {} # Fallback, although the ||= should prevent this
                        # break
                    end
                end
            end

            sorted_tree = sort_tree(tree)
            self.debug_json("SiteContentMapBuilder", "build_tree", "Sorted tree:\n", sorted_tree)
            return sorted_tree
        end

        # Recursively sort tree nodes by `order` then title
        def sort_tree(tree)
            self.debug_print("SiteContentMapBuilder", "sort_tree", "Starting to sort tree...")
            sorted = {}

            # Get an array containing only the sorted keys (e.g., ["site_content", "posts", "assets"]).
            sorted_keys = tree.keys.sort_by do |key|
                page_data = tree[key]["__page__"] || {}
                [page_data["order"] || 0, page_data["title"] || key]
                # {page_data["order"] || 0, page_data["title"] || key}
            # end.each do |key|
            end
            # Iterate over the explicit array of sorted keys
            sorted_keys.each do |key|
                self.debug_print("SiteContentMapBuilder", "sort_tree", "Looking at key '#{key}'...")
                node = tree[key]
                # children_array = node["__children__"]
                # debug_json("SiteContentMapBuilder", "sort_tree", "Children array:", children_array)

                # # Convert children array back to hash for recursion
                # children_hash = {}
                # if children_array
                #     # children_array.each do |child|
                #     children_array.each do |subkey, child|
                #         debug_json("SiteContentMapBuilder", "sort_tree", "Re-hashing subkey '#{subkey}' with child:", child)
                #         debug_print("SiteContentMapBuilder", "sort_tree", "Child has length #{child.length}...")
                #         # children_hash.merge!(child) if child
                #         if child.is_a?(Hash)
                #             # Merge the child hash into the parent children_hash
                #             children_hash.merge!(child)
                #         end
                #     end
                # end

                # # node["__children__"] = sort_tree(children_hash) unless children_hash.empty?
                # # Recursively sort the children_hash
                # # The check ensures we only recurse if children_hash actually contains data.
                # if !children_hash.empty?
                #     debug_json("SiteContentMapBuilder", "sort_tree", "Recursing into children_hash:", children_hash)
                #     node["__children__"] = sort_tree(children_hash) 
                # end

                # # Assign the (potentially modified) node to the sorted result hash
                # sorted[key] = node

                # Start by copying the node (this ensures we keep the attributes like __page__)
                sorted[key] = node.dup

                # Get the existing children hash (or empty hash if none exist)
                children_container = node["__children__"] || {}
                
                # Handle Recursion:
                if !children_container.empty?
                    # Check if the children container itself is a Hash before recursing.
                    if children_container.is_a?(Hash)
                        # Recursively sort the children and assign the fully sorted hash back to the node.
                        self.debug_json("SiteContentMapBuilder", "sort_tree", "Recursing into children_container:", children_container)
                        sorted[key]["__children__"] = sort_tree(children_container) 
                    end
                end
            end

            return sorted
        end
        # DebugUtils.set_debug_mode(false)
    end

    class SiteContentMapBuilderTag < Liquid::Tag
        # Syntax = /(#{Liquid::QuotedFragment}+)\s(\d+)\s(\d+)\s\z/o
        # Updated Regex:
        # (.*?) captures ANY content non-greedily for the first argument ($1)
        # \s+ matches one or more spaces
        # (\d+) captures the integer ($2)
        # \s* matches optional trailing spaces
        Syntax = /(.+?)\s+(\d+)\s*$/o
        include DebugUtils
        # DebugUtils.set_debug_mode(false)

        def initialize(_tag_name, markup, _parse_context)
            super
            if markup =~ Syntax
                @site_content = $1
                @max_depth = $2.to_i
            else
                raise "Syntax error in site_content_map_builder. Expected format: <liquid_expr> <integer> (Found: #{markup})"
            end
            #@markup = markup.strip
        end
    
        def render(context)
            map_builder = SiteContentMapBuilder.new
            # Looks like "context" also has "collections" 
            # which is a list that contains "posts" and 
            # "site_content" as hashes with those as 
            # the value for the "label" attr?
            # And it also contains "posts" (empty, right now) directly.
            # And "documents".
            # And "data", which contains the "site_content_map" as built above?
            # And it also contains "pages".
            # Though these may not be directly in the context object?
            # These may be nested under "site".
            # # But I guess if it already contains "data", we could just render 
            # # directly "context.data.site_content_map", and not worry about
            # # calling the generate method again anymore?
            # # debug_json("SiteContentMapBuilderTag", "render", "Previously enerated site_content_map:", context.data.site_content_map)
            # # debug_json("SiteContentMapBuilderTag", "render", "Previously generated site_content_map:", context["data"]["site_content_map"])
            self.debug_json("SiteContentMapBuilderTag", "render", "Previously generated site_content_map:", context["site"]["data"]["site_content_map"])
            # data = context["data"]
            # debug_json("SiteContentMapBuilderTag", "render", "data: ", data)
            # debug_json("SiteContentMapBuilderTag", "render", "Previously generated site_content_map\n:", data["site_content_map"])
            # debug_json("SiteContentMapBuilderTag", "render", "context[\"site\"]:\n", context["site"])
            # map = map_builder.generate(context["site"])
            map = context["site"]["data"]["site_content_map"]
            # DebugUtils.set_debug_mode(true)
            self.debug_print("SiteContentMapBuilderTag", "render","Got the map:")
            # DebugUtils.set_debug_mode(false)
            self.debug_p(map)
            return map
        end
        Liquid::Template.register_tag('site_content_map_builder', SiteContentMapBuilderTag)
    end
    # DebugUtils.set_debug_mode(false)
end
