module Asciidoctor
  module Gb

    # A {Converter} implementation that generates GB output, and a document
    # schema encapsulation of the document for validation
    class Converter < ISO::Converter

      def term_def_subclause_parse(attrs, xml, node)
        # subclause contains subclauses
        sub = node.find_by(context: :section) {|s| s.level == node.level + 1 }
        sub.empty? || (return term_def_parse(attrs, xml, node, false))
        (node.title.downcase == "symbols and abbreviated terms" ||
        node.title == "符号、代号和缩略语") &&
          (return symbols_parse(attrs, xml, node))
        xml.term **attr_code(attrs) do |xml_section|
          xml_section.preferred { |name| name << node.title }
          xml_section << node.content
        end
      end

      def section(node)
        a = { id: Asciidoctor::ISO::Utils::anchor_or_uuid(node) }
        noko do |xml|
          case sectiontype(node)
          when "引言" then
            if node.level == 1 then introduction_parse(a, xml, node)
            else
              clause_parse(a, xml, node)
            end
          when "patent notice" then patent_notice_parse(xml, node)
          when "范围", "scope" then scope_parse(a, xml, node)
          when "规范性引用文件", "normative references"
            norm_ref_parse(a, xml, node)
          when "术语和定义", "terms and definitions",
            "术语、定义、符号、代号和缩略语",
            "terms, definitions, symbols and abbreviated terms"
            @term_def = true
            term_def_parse(a, xml, node, true)
            @term_def = false
          when "符号、代号和缩略语", "symbols and abbreviated terms"
            symbols_parse(a, xml, node)
          when "参考文献", "bibliography"
            bibliography_parse(a, xml, node)
          else
            if @term_def then term_def_subclause_parse(a, xml, node)
            elsif @biblio then bibliography_parse(a, xml, node)
            elsif node.attr("style") == "appendix" && node.level == 1
              annex_parse(a, xml, node)
            else
              clause_parse(a, xml, node)
            end
          end
        end.join("\n")
      end

      def normref_cleanup(xmldoc)
        q = "//references[title = '规范性引用文件']"
        r = xmldoc.at(q)
        if r.nil?
          warn "You have no normative references!"
          return
        end
        r.elements.each do |n|
          n.remove unless ["title", "bibitem"].include? n.name
        end
      end

      def normref_validate(root)
        f = root.at("//references[title = '规范性引用文件']") ||
          return
        f.at("./references") &&
          warn("ISO style: normative references contains subsections")
      end

      def symbols_validate(root)
        f = root.at("//clause[title = '符号、代号和缩略语']")
        return if f.nil?
        f.elements do |e|
          unless e.name == "dl"
            warn "ISO style: Symbols and Abbreviations can only contain "\
              "a definition list"
            return
          end
        end
      end

      # spec of permissible section sequence
      SEQ = [
        { msg: "Initial section must be (content) 前言",
          val:  [{ tag: "foreword", title: "前言" }], },
      { msg: "Prefatory material must be followed by (clause) 范围",
        val:  [{ tag: "introduction", title: "引言" },
               { tag: "clause", title: "范围" }], },
      { msg: "Prefatory material must be followed by (clause) 范围",
        val: [{ tag: "clause", title: "范围" }], },
      { msg: "规范性引用文件 must be followed by "\
        "术语和定义",
        val: [
          { tag: "terms", title: "术语和定义" },
          { tag: "terms",
            title: "术语、定义、符号、代号和缩略语" }
        ] },
      ]

      def sections_sequence_validate(root)
        f = root.xpath(" //foreword | //introduction | //sections/terms | "\
                       "//sections/clause | ./references | "\
                       "./annex")
        names = f.map { |s| { tag: s.name, title: s.at("./title").text } }
        names = seqcheck(names, SEQ[0][:msg], SEQ[0][:val]) || return
        n = names[0]
        names = seqcheck(names, SEQ[1][:msg], SEQ[1][:val]) || return
        if n == { tag: "introduction", title: "引言" }
          names = seqcheck(names, SEQ[2][:msg], SEQ[2][:val]) || return
        end
        names = seqcheck(names, SEQ[3][:msg], SEQ[3][:val]) || return
        n = names.shift
        if n == { tag: "clause", title: "符号、代号和缩略语" }
          n = names.shift
        end
        unless n
          warn "ISO style: Document must contain at least one clause"
          return
        end
        n[:tag] == "clause" or
          warn "ISO style: Document must contain at least one clause"
        (n == { tag: "clause", title: "范围" }) &&
          warn("ISO style: 范围 must occur before 术语和定义")
        n = names.shift or return
        while n[:tag] == "clause"
          (n[:title] == "范围") &&
            warn("ISO style: 范围 must occur before 术语和定义")
          n[:title] == "符号、代号和缩略语" and
            warn "ISO style: 符号、代号和缩略语 must occur "\
            "right after Terms and Definitions"
          n = names.shift or return
        end
        unless n[:tag] == "annex" or n[:tag] == "references"
          warn "ISO style: Only annexes and references can follow clauses"
        end
        while n[:tag] == "annex"
          n = names.shift or return
        end
        n == { tag: "references", title: "规范性引用文件" } or
          warn "ISO style: Document must include (references) 规范性引用文件"
        n = names.shift
        n == { tag: "references", title: "参考文献" } or
          warn "ISO style: Final section must be (references) 参考文献"
        names.empty? or
          warn "ISO style: There are sections after the final Bibliography"
      end
    end
  end
end
