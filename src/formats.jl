# TODO:
# - 1. do assertions for definition mandatory fields in `@define_format` macro
# - 2. implement fallback format/rendering functions in format.jl
# - 3. export this as public API


abstract type WeaveFormat end
const FORMATS = Dict{String,WeaveFormat}()

macro define_format(ex)
    return if ex isa Symbol
        quote
            struct $(ex) <: $(WeaveFormat)
                formatdict::Dict{Symbol,Any}
            end
        end
    elseif Meta.isexpr(ex, :<:)
        type_name, supertype = ex.args
        quote
            @assert $(esc(supertype)) <: $(WeaveFormat) "$($(esc(supertype))) should be subtype of WeaveFormat"
            struct $(type_name) <: $(esc(supertype))
                formatdict::Dict{Symbol,Any}
            end
        end
    else
        error("@define_format expects T or T<:S expression")
    end
end
# TODO: do some assertion for necessary fields of `formatdict`
register_format!(format_name::AbstractString, format::WeaveFormat) = push!(FORMATS, format_name => format)

# HTML
# ----

@define_format JMarkdown2HTML
register_format!("md2html", JMarkdown2HTML(Dict(
    :description => "Julia markdown to html",
    :codestart => "\n",
    :codeend => "\n",
    :outputstart => "<pre class=\"output\">",
    :outputend => "</pre>\n",
    :fig_ext => ".png",
    :mimetypes => [
        "image/png",
        "image/jpg",
        "image/svg+xml",
        "text/html",
        "text/markdown",
        "text/plain",
    ],
    :extension => "html",
)))

@define_format Pandoc2HTML
register_format!("pandoc2html", Pandoc2HTML(Dict(
    :description => "Markdown to HTML (requires Pandoc 2)",
    :codestart => "\n",
    :codeend => "\n",
    :outputstart => "\n",
    :outputend => "\n",
    :fig_ext => ".png",
    :extension => "md",
    :mimetypes => [
        "image/png",
        "image/svg+xml",
        "image/jpg",
        "text/html",
        "text/markdown",
        "text/plain",
    ],
)))


# PDF and Tex
# -----------

abstract type TexFormat <: WeaveFormat end

@define_format JMarkdown2tex <: TexFormat
let t = JMarkdown2tex(Dict(
        :description => "Julia markdown to latex",
        :codestart => "",
        :codeend => "",
        :outputstart => "\\begin{lstlisting}",
        :outputend => "\\end{lstlisting}\n",
        :fig_ext => ".pdf",
        :extension => "tex",
        :out_width => "\\linewidth",
        :mimetypes => [
            "application/pdf",
            "image/png",
            "image/jpg",
            "text/latex",
            "text/markdown",
            "text/plain",
        ],
        :keep_unicode => false,
    ))
    register_format!("md2pdf", t)
    register_format!("md2tex", t)
end

@define_format Tex <: TexFormat
register_format!("tex", Tex(Dict(
    :description => "Latex with custom code environments",
    :codestart => "\\begin{juliacode}",
    :codeend => "\\end{juliacode}",
    :outputstart => "\\begin{juliaout}",
    :outputend => "\\end{juliaout}",
    :termstart => "\\begin{juliaterm}",
    :termend => "\\end{juliaterm}",
    :fig_ext => ".pdf",
    :extension => "tex",
    :out_width => "\\linewidth",
    :fig_env => "figure",
    :fig_pos => "htpb",
    :mimetypes => ["application/pdf", "image/png", "text/latex", "text/plain"],
    :keep_unicode => false,
)))

@define_format TexMinted <: TexFormat
register_format!("texminted", TexMinted(Dict(
    :description => "Latex using minted for highlighting",
    :codestart =>
        "\\begin{minted}[mathescape, fontsize=\\small, xleftmargin=0.5em]{julia}",
    :codeend => "\\end{minted}",
    :outputstart =>
        "\\begin{minted}[fontsize=\\small, xleftmargin=0.5em, mathescape, frame = leftline]{text}",
    :outputend => "\\end{minted}",
    :termstart =>
        "\\begin{minted}[fontsize=\\footnotesize, xleftmargin=0.5em, mathescape]{jlcon}",
    :termend => "\\end{minted}",
    :fig_ext => ".pdf",
    :extension => "tex",
    :out_width => "\\linewidth",
    :fig_env => "figure",
    :fig_pos => "htpb",
    :mimetypes => ["application/pdf", "image/png", "text/latex", "text/plain"],
    :keep_unicode => false,
)))


# pandoc
# ------

@define_format Pandoc
let p = Pandoc(Dict(
        :description => "Pandoc markdown",
        :codestart => "~~~~{.julia}",
        :codeend => "~~~~~~~~~~~~~\n\n",
        :outputstart => "~~~~",
        :outputend => "~~~~\n\n",
        :fig_ext => ".png",
        :out_width => nothing,
        :extension => "md",
        # Prefer png figures for markdown conversion, svg doesn't work with latex
        :mimetypes =>
            ["image/png", "image/jpg", "image/svg+xml", "text/markdown", "text/plain"],
    ))
    register_format!("pandoc", p)
    register_format!("pandoc2pdf", p)
end


# markdown
# --------

@define_format GitHubMarkdown
register_format!("github", GitHubMarkdown(Dict(
    :description => "GitHub markdown",
    :codestart => "````julia",
    :codeend => "````\n\n",
    :outputstart => "````",
    :outputend => "````\n\n",
    :fig_ext => ".png",
    :extension => "md",
    :mimetypes =>
        ["image/png", "image/svg+xml", "image/jpg", "text/markdown", "text/plain"],
)))

@define_format Hugo
register_format!("hugo", Hugo(Dict(
    :description => "Hugo markdown (using shortcodes)",
    :codestart => "````julia",
    :codeend => "````\n\n",
    :outputstart => "````",
    :outputend => "````\n\n",
    :fig_ext => ".png",
    :extension => "md",
    :uglyURLs => false, # if `false`, prepend figure path by `..`
)))

@define_format MultiMarkdown
register_format!("multimarkdown", MultiMarkdown(Dict(
    :description => "MultiMarkdown",
    :codestart => "````julia",
    :codeend => "````\n\n",
    :outputstart => "````",
    :outputend => "````\n\n",
    :fig_ext => ".png",
    :extension => "md",
)))


# Rest
# ----

@define_format Rest
register_format!("rst", Rest(Dict(
    :description => "reStructuredText and Sphinx",
    :codestart => ".. code-block:: julia\n",
    :codeend => "\n\n",
    :outputstart => "::\n",
    :outputend => "\n\n",
    :indent => 4,
    :fig_ext => ".png",
    :extension => "rst",
    :out_width => "15 cm",
)))


# Ansii
# -----

# asciidoc -b html5 -a source-highlighter=pygments ...
@define_format AsciiDoc
register_format!("asciidoc", AsciiDoc(Dict(
    :description => "AsciiDoc",
    :codestart => "[source,julia]\n--------------------------------------",
    :codeend => "--------------------------------------\n\n",
    :outputstart => "--------------------------------------",
    :outputend => "--------------------------------------\n\n",
    :fig_ext => ".png",
    :extension => "txt",
    :out_width => "600",
)))


# TODO: move this functions where used
# ------------------------------------

using Printf


function md_length_to_latex(def, reference)
    if occursin("%", def)
        _def = tryparse(Float64, replace(def, "%" => ""))
        _def == nothing && return def
        perc = round(_def / 100, digits = 2)
        return "$perc$reference"
    end
    return def
end

function formatfigures(chunk, docformat::JMarkdown2HTML)
    fignames = chunk.figures
    caption = chunk.options[:fig_cap]
    width = chunk.options[:out_width]
    height = chunk.options[:out_height]
    f_pos = chunk.options[:fig_pos]
    f_env = chunk.options[:fig_env]
    result = ""
    figstring = ""

    # Set size
    attribs = ""
    width == nothing || (attribs = "width=\"$width\"")
    (attribs != "" && height != nothing) && (attribs *= ",")
    height == nothing || (attribs *= " height=\"$height\" ")

    if caption != nothing
        result *= """<figure>\n"""
    end

    for fig in fignames
        figstring *= """<img src="$fig" $attribs />\n"""
    end

    result *= figstring

    if caption != nothing
        result *= """
          <figcaption>$caption</figcaption>
          """
    end

    if caption != nothing
        result *= "</figure>\n"
    end

    return result
end

function formatfigures(chunk, docformat::TexFormat)
    fignames = chunk.figures
    caption = chunk.options[:fig_cap]
    width = chunk.options[:out_width]
    height = chunk.options[:out_height]
    f_pos = chunk.options[:fig_pos]
    f_env = chunk.options[:fig_env]
    result = ""
    figstring = ""

    if f_env == nothing && caption != nothing
        f_env = "figure"
    end

    (f_pos == nothing) && (f_pos = "!h")
    # Set size
    attribs = ""
    width == nothing || (attribs = "width=$(md_length_to_latex(width,"\\linewidth"))")
    (attribs != "" && height != nothing) && (attribs *= ",")
    height == nothing || (attribs *= "height=$(md_length_to_latex(height,"\\paperheight"))")

    if f_env != nothing
        result *= "\\begin{$f_env}"
        (f_pos != "") && (result *= "[$f_pos]")
        result *= "\n"
    end

    for fig in fignames
        if splitext(fig)[2] == ".tex" # Tikz figures
            figstring *= "\\resizebox{$width}{!}{\\input{$fig}}\n"
        else
            if isempty(attribs)
                figstring *= "\\includegraphics{$fig}\n"
            else
                figstring *= "\\includegraphics[$attribs]{$fig}\n"
            end
        end
    end

    # Figure environment
    if caption != nothing
        result *= string("\\center\n", "$figstring", "\\caption{$caption}\n")
    else
        result *= figstring
    end

    if chunk.options[:label] != nothing && f_env != nothing
        label = chunk.options[:label]
        result *= "\\label{fig:$label}\n"
    end

    if f_env != nothing
        result *= "\\end{$f_env}\n"
    end

    return result
end

formatfigures(chunk, docformat::Pandoc2HTML) = formatfigures(chunk, pandoc)

function formatfigures(chunk, docformat::Pandoc)
    fignames = chunk.figures
    length(fignames) > 0 || (return "")

    caption = chunk.options[:fig_cap]
    label = get(chunk.options, :label, nothing)
    result = ""
    figstring = ""
    attribs = ""
    width = chunk.options[:out_width]
    height = chunk.options[:out_height]

    # Build figure attibutes
    attribs = String[]
    width == nothing || push!(attribs, "width=$width")
    height == nothing || push!(attribs, "height=$height")
    label == nothing || push!(attribs, "#fig:$label")
    attribs = isempty(attribs) ? "" : "{" * join(attribs, " ") * "}"

    if caption != nothing
        result *= "![$caption]($(fignames[1]))$attribs\n"
        for fig in fignames[2:end]
            result *= "![]($fig)$attribs\n"
            println("Warning, only the first figure gets a caption\n")
        end
    else
        for fig in fignames
            result *= "![]($fig)$attribs\\ \n\n"
        end
    end
    return result
end

function formatfigures(chunk, docformat::GitHubMarkdown)
    fignames = chunk.figures
    caption = chunk.options[:fig_cap]
    result = ""
    figstring = ""

    length(fignames) > 0 || (return "")

    if caption != nothing
        result *= "![$caption]($(fignames[1]))\n"
        for fig in fignames[2:end]
            result *= "![]($fig)\n"
            println("Warning, only the first figure gets a caption\n")
        end
    else
        for fig in fignames
            result *= "![]($fig)\n"
        end
    end
    return result
end

function formatfigures(chunk, docformat::Hugo)
    relpath = docformat.formatdict[:uglyURLs] ? "" : ".."
    function format_shortcode(index_and_fig)
        index, fig = index_and_fig
        if index > 1
            @warn("Only the first figure gets a caption.")
            title_spec = ""
        else
            caption = chunk.options[:fig_cap]
            title_spec = caption == nothing ? "" : "title=\"$(caption)\" "
        end
        "{{< figure src=\"$(joinpath(relpath, fig))\" $(title_spec) >}}"
    end
    mapreduce(format_shortcode, *, enumerate(chunk.figures), init = "")
end

function formatfigures(chunk, docformat::MultiMarkdown)
    fignames = chunk.figures
    caption = chunk.options[:fig_cap]
    result = ""
    figstring = ""

    if chunk.options[:out_width] == nothing
        width = ""
    else
        width = "width=$(chunk.options[:out_width])"
    end

    length(fignames) > 0 || (return "")

    if caption != nothing
        result *= "![$caption][$(fignames[1])]\n\n"
        result *= "[$(fignames[1])]: $(fignames[1]) $width\n"
        for fig in fignames[2:end]
            result *= "![][$fig]\n\n"
            result *= "[$fig]: $fig $width\n"
            println("Warning, only the first figure gets a caption\n")
        end
    else
        for fig in fignames
            result *= "![][$fig]\n\n"
            result *= "[$fig]: $fig $width\n"
        end
    end
    return result
end

function formatfigures(chunk, docformat::Rest)
    fignames = chunk.figures
    caption = chunk.options[:fig_cap]
    width = chunk.options[:out_width]
    result = ""
    figstring = ""

    for fig in fignames
        figstring *= @sprintf(".. image:: %s\n   :width: %s\n\n", fig, width)
    end

    if caption != nothing
        result *= string(
            ".. figure:: $(fignames[1])\n",
            "   :width: $width\n\n",
            "   $caption\n\n",
        )
    else
        result *= figstring
        return result
    end
end

function formatfigures(chunk, docformat::AsciiDoc)
    fignames = chunk.figures
    caption = chunk.options[:fig_cap]
    width = chunk.options[:out_width]
    result = ""
    figstring = ""

    for fig in fignames
        figstring *= @sprintf("image::%s[width=%s]\n", fig, width)
    end

    if caption != nothing
        result *= string("image::$(fignames[1])", "[width=$width,", "title=\"$caption\"]")
    else
        result *= figstring
        return result
    end
end
