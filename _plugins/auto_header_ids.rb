# module Jekyll
#     class AutoHeaderIds < Generator
#         priority :low

#         def generate(site)
#             site.pages.each do |page|
#                 page.output = add_ids_to_headers(page.output) if page.output_ext == '.html'
#             end

#             site.posts.docs.each do |post|
#                 post.output = add_ids_to_headers(post.output) if post.output_ext == '.html'
#             end
#         end
module AddIdsToHeaderFilter
        def add_ids_to_headers(content)
            return content if content.nil?

            # Matches direct <h1> through <h6> tags
            content.gsub(/<h([1-6])(.*?)>(.*?)<\/h\1>/i) do |match|
                level = $1
                attributes = $2
                text = $3

                # Skip if an ID is already present
                if attributes =~ /id=/
                    match
                else
                    # Slugify the text to use as an ID
                    slug = text.downcase.strip.gsub(/\s+/, '-').gsub(/[^\w-]/, '')
                    "<h#{level}#{attributes} id=\"#{slug}\">#{text}</h#{level}>"
                end
            end
        end
    # end
    Liquid::Template.register_filter(AddIdsToHeaderFilter)
end
