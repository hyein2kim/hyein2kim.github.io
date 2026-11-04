# frozen_string_literal: true

# Makes notes written in Obsidian render on the site as they do in the app,
# and keeps notes that are not ready from being published.
module ObsidianMarkdown
  IMAGE_EXTENSIONS = %w[.png .jpg .jpeg .gif .svg .webp .avif .bmp].freeze
  MARKDOWN_EXTENSIONS = %w[.md .markdown].freeze

  # Text the converters must leave alone. A comment is removed instead of kept.
  PROTECTED = /
    (?<comment>%%.*?(?:%%|\z)) |
    ^(?<quote>(?:>[ ]?)*)(?<fence>[ ]{0,3}(?<mark>`{3,}|~{3,})[^\n]*\n.*?(?:^[>[ ]]*\k<mark>[ \t]*$|\z)) |
    (?<code>(?<!`)(?<ticks>`+)(?!`)[^\n]*?(?<!`)\k<ticks>(?!`)) |
    (?<html><\/?[a-zA-Z][^<>\n]*>) |
    (?<url>https?:\/\/[^\s)>\]]+)
  /mx.freeze

  PLACEHOLDER = /\uE000(\d+)\uE000/.freeze
  CALLOUT = /^>[ ]?\[!(?<type>[\w-]+)\][+-]?[ \t]*(?<title>[^\n]*)\n?(?<body>(?:^>[^\n]*\n?)*)/.freeze
  WIKILINK = /(?<embed>!?)\[\[(?<inner>[^\]\n]+)\]\]/.freeze
  HIGHLIGHT = /(?<!=)==(?![=\s])(?<text>[^\n]+?)(?<![=\s])==(?!=)/.freeze

  class << self
    def build_index(site)
      @notes = site.documents.to_h { |doc| [key_for(File.basename(doc.path, ".*")), doc] }
      @files = site.static_files.to_h { |file| [key_for(file.name), file] }
      @baseurl = site.baseurl.to_s
    end

    def convert(text, source)
      stash = []
      text = protect(text, stash)
      text = convert_callouts(text)
      text = text.gsub(WIKILINK) { convert_wikilink(Regexp.last_match, source) }
      text = text.gsub(HIGHLIGHT) { "<mark>#{Regexp.last_match[:text]}</mark>" }
      restore(text, stash)
    end

    # Jekyll capitalizes a title it derives from the filename; keep the note's own name.
    def use_filenames_as_titles(site)
      site.documents.each do |doc|
        front_matter = File.read(doc.path, encoding: "utf-8")[Jekyll::Document::YAML_FRONT_MATTER_REGEXP, 1]
        doc.data["title"] = File.basename(doc.path, ".*") unless front_matter.to_s.match?(/^title:[ \t]*\S/)
      end
    end

    def drop_unpublishable_files(site)
      site.static_files.reject! do |file|
        next false unless markdown?(file.name)

        Jekyll.logger.warn "Obsidian:", "skipped #{file.relative_path}: no front matter"
        true
      end
      site.collections.each_value { |collection| collection.files.reject! { |file| markdown?(file.name) } }
    end

    def markdown?(name)
      MARKDOWN_EXTENSIONS.include?(File.extname(name).downcase)
    end

    private

    def key_for(name)
      name.unicode_normalize(:nfc).downcase
    end

    def protect(text, stash)
      text.gsub(PROTECTED) do
        match = Regexp.last_match
        next "" if match[:comment]

        stash << (match[:fence] || match[0])
        "#{match[:quote]}\uE000#{stash.size - 1}\uE000"
      end
    end

    def restore(text, stash)
      text = text.gsub(PLACEHOLDER) { stash[Regexp.last_match(1).to_i] } while text.match?(PLACEHOLDER)
      text
    end

    # Stays a blockquote so that kramdown still applies hard_wrap to its text.
    def convert_callouts(text)
      text.gsub(CALLOUT) do
        match = Regexp.last_match
        type = match[:type].downcase
        title = match[:title].strip.empty? ? type.capitalize : match[:title].strip
        body = convert_callouts(match[:body].gsub(/^>[ ]?/, ""))
        quoted_body = body.rstrip.gsub(/^/, "> ")

        "> #{title}\n> {: .callout-title}\n>\n#{quoted_body}\n{: .callout .callout-#{type}}\n\n"
      end
    end

    def convert_wikilink(match, source)
      target, label = match[:inner].split(/\\?\|/, 2).map(&:strip)
      name = target.to_s.split("#", 2).first.to_s
      return label || target.to_s.delete_prefix("#") if name.empty?

      if match[:embed] == "!" && (file = @files[key_for(File.basename(name))])
        return embed_file(file, label)
      end

      link_to(name, label, source)
    end

    def embed_file(file, label)
      url = @baseurl + Jekyll::URL.escape_path(file.relative_path)
      return "[#{label || file.name}](#{url})" unless IMAGE_EXTENSIONS.include?(File.extname(file.name).downcase)

      width = label.to_s[/\A(\d+)(?:x\d+)?\z/, 1]
      return "![](#{url}){: width=\"#{width}\"}" if width

      "![#{label}](#{url})"
    end

    def link_to(name, label, source)
      basename = File.basename(name)
      note = @notes[key_for(basename.sub(/\.md\z/i, ""))]
      text = label || basename
      return "[#{text}](#{@baseurl}#{note.url})" if note

      # Linked notes that are unpublished or missing must not become dead links.
      Jekyll.logger.warn "Obsidian:", "#{source}: no published note or file for [[#{name}]]"
      text
    end
  end
end

Jekyll::Hooks.register(:site, :post_read) { |site| ObsidianMarkdown.drop_unpublishable_files(site) }

Jekyll::Hooks.register(:site, :pre_render) do |site|
  ObsidianMarkdown.use_filenames_as_titles(site)
  ObsidianMarkdown.build_index(site)
end

Jekyll::Hooks.register(:documents, :pre_render) do |doc|
  next unless ObsidianMarkdown.markdown?(doc.path)

  doc.content = ObsidianMarkdown.convert(doc.content, doc.relative_path)
end
